// SL 2020-06-12 @sylefeb
//
// Fun with RISC-V!   RV32I cpu, see README.md
//
//      GNU AFFERO GENERAL PUBLIC LICENSE
//        Version 3, 19 November 2007
//      
//  A copy of the license full text is included in 
//  the distribution, please refer to it for details.

// --------------------------------------------------
// Processor
// --------------------------------------------------

// bitfield for easier decoding of instructions
bitfield Rtype { uint1 unused1, uint1 sign, uint5 unused2, uint5 rs2, 
                 uint5 rs1,     uint3 op,   uint5 rd,      uint7 opcode}

// --------------------------------------------------
// execute: decoder + ALU
// - decodes instructions
// - performs all integer computations

algorithm execute(
  // instruction, program counter and registers
  input  uint32 instr, input  uint$addrW$ pc, input int32 xa, input int32 xb,
  // trigger: pulsed high when the decoder + ALU should start
  input  uint1  trigger, input   uint1  cpu_id,
  // outputs all information the processor needs to decide what to do next 
  output uint3  op,    output uint5  write_rd, output  uint1  no_rd, 
  output uint1  jump,  output uint1  load,     output  uint1  store,  
  output int32  val,   output uint1  storeVal, output  uint1  working(0),
  output uint32 n,     output uint1  storeAddr, // next address adder
  output uint1  intop, output int32  r,         // integer operations
) {
  uint5  shamt(0);  uint24 cycle(0); // shifter status and cycle counter

  // ==== decode immediates
  int32 imm_u  <: {instr[12,20],12b0};
  int32 imm_j  <: {{12{instr[31,1]}},instr[12,8],instr[20,1],instr[21,10],1b0};
  int32 imm_i  <: {{20{instr[31,1]}},instr[20,12]};
  int32 imm_b  <: {{20{instr[31,1]}},instr[7,1],instr[25,6],instr[8,4],1b0};
  int32 imm_s  <: {{20{instr[31,1]}},instr[25,7],instr[7,5]};

  // ==== decode opcode
  uint5 opcode    <: instr[ 2, 5];
  uint1 AUIPC     <: opcode == 5b00101;  uint1 LUI    <: opcode == 5b01101;
  uint1 JAL       <: opcode == 5b11011;  uint1 JALR   <: opcode == 5b11001;
  uint1 IntImm    <: opcode == 5b00100;  uint1 IntReg <: opcode == 5b01100;
  uint1 Cycles    <: opcode == 5b11100;  uint1 branch <: opcode == 5b11000;
  uint1 regOrImm  <: IntReg  | branch;                    // reg or imm in ALU?
  uint1 pcOrReg   <: AUIPC   | JAL    | branch;           // pc or reg in addr?
  uint1 sub       <: IntReg  & Rtype(instr).sign;         // subtract
  uint1 aluShift  <: (IntImm | IntReg) & op[0,2] == 2b01; // shift requested

  // ==== select next address adder first input
  int32 addr_a    <: pcOrReg ? __signed({pc[0,$addrW-2$],2b0}) : xa;
  // ==== select ALU second input 
  int32 b         <: regOrImm ? (xb) : imm_i;
    
  // ==== allows to do subtraction and all comparisons with a single adder
  // trick from femtorv32/swapforth/J1
  int33 a_minus_b <: {1b1,~b} + {1b0,xa} + 33b1;
  uint1 a_lt_b    <: (xa[31,1] ^ b[31,1]) ? xa[31,1] : a_minus_b[32,1];
  uint1 a_lt_b_u  <: a_minus_b[32,1];
  uint1 a_eq_b    <: a_minus_b[0,32] == 0;

  // ==== select immediate for the next address computation
  // 'or trick' from femtorv32
  int32 addr_imm  <: (AUIPC  ? imm_u : 32b0) | (JAL         ? imm_j : 32b0)
                  |  (branch ? imm_b : 32b0) | ((JALR|load) ? imm_i : 32b0)
                  |  (store  ? imm_s : 32b0);
  // ==== set decoder outputs depending on incoming instructions
  // load/store?
  load         := opcode == 5b00000;   store        := opcode == 5b01000;   
  // operator for load/store           // register to write to?
  op           := Rtype(instr).op;     write_rd     := Rtype(instr).rd;    
  // do we have to write a result to a register?
  no_rd        := branch  | store  | (Rtype(instr).rd == 5b0);
  // integer operations                // store next address?
  intop        := (IntImm | IntReg);   storeAddr    := AUIPC;  
  // value to store directly           
  val          := LUI ? imm_u : {cpu_id,7b0,cycle}; 
  // store value?
  storeVal     := LUI     | Cycles;   
  
  always {
    int32 shift(0);  uint1 j(0); // temp variables for shifter and comparator

    // ====================== ALU
    // shift (one bit per clock)
    if (working) {
      // decrease shift size
      shamt = shamt - 1;
      // shift one bit
      shift = op[2,1] ? (Rtype(instr).sign ? {r[31,1],r[1,31]} 
                          : {__signed(1b0),r[1,31]}) : {r[0,31],__signed(1b0)};      
    } else {
      // start shifting?
      shamt = ((aluShift & trigger) ? __unsigned(b[0,5]) : 0);
      // store value to be shifted
      shift = xa;
    }
    // are we still shifting?
    working = (shamt != 0);

    // all ALU operations
    switch (op) {
      case 3b000: { r = sub ? a_minus_b : xa + b; }            // ADD / SUB
      case 3b010: { r = a_lt_b; } case 3b011: { r = a_lt_b_u; }// SLTI / SLTU
      case 3b100: { r = xa ^ b; } case 3b110: { r = xa | b;   }// XOR / OR
      case 3b001: { r = shift;  } case 3b101: { r = shift;    }// SLLI/SRLI/SRAI
      case 3b111: { r = xa & b; }     // AND
      default:    { r = {32{1bx}}; }  // don't care
    } 
$$if SIMULATION then         
    if (trigger) {
      __display("[cycle %d] ALU xa:%h b:%h (shamt:%d r:%h)",cycle,xa,b,shamt,r);
    }
$$end    
    // ====================== Comparator for branching
    switch (op[1,2]) {
      case 2b00:  { j = a_eq_b;  } /*BEQ */ case 2b10: { j=a_lt_b;} /*BLT*/ 
      case 2b11:  { j = a_lt_b_u;} /*BLTU*/ default:   { j = 1bx; }
    }
    jump = (JAL | JALR) | (branch & (j ^ op[0,1]));
    //                                   ^^^^^^^ negates comparator result

    // ====================== Next address adder
    n = addr_a + addr_imm;
  
    // ==== increment cycle counter
    cycle = cycle + 1; 

  }
  
}

// --------------------------------------------------
// The Risc-V RV32I CPU itself

algorithm rv32i_cpu(bram_port mem) <onehot> {

  // uint32 cycle(0);

  // register files, two BRAMs to fetch two registers at once
  bram int32 xregsA_0[32] = {0,pad(uninitialized)}; bram int32 xregsB_0[32] = {0,pad(uninitialized)};
  bram int32 xregsA_1[32] = {0,pad(uninitialized)}; bram int32 xregsB_1[32] = {0,pad(uninitialized)};

  // current instruction
  uint32 instr_0(0);
  uint32 instr_1(0);

  // CPU states
  uint4  stage_0(4b1000); // F  , T  , LS1, LS2
  uint4  stage_1(4b0010); // 3    2    1    0
  // TODO ^^^^^^^^^^^^^ merge? one is enough?

  // program counter
  uint$addrW$ pc_0(0);
  //uint$addrW$ next_pc_0 <:: pc_0 + 1; // next_pc tracks the expression 'pc + 1'
  uint$addrW$ pc_1(-1);
  //uint$addrW$ next_pc_1 <:: pc_1 + 1; // next_pc tracks the expression 'pc + 1'
  uint$addrW$ next_pc <: ((stage_0[0,1]|stage_0[3,1]) ? pc_0 : pc_1) + 1;

  // value that has been loaded from memory
  int32 loaded     = uninitialized;

  // decoder + ALU, executes the instruction and tells processor what to do
  execute exec;

$$if SIMULATION then         
  uint32 cycle(0);
$$end

  // what do we write in register? (pc, alu or val, load is handled separately)
  int32 write_back <: (exec.jump      ? (next_pc<<2)        : 32b0)
                    | (exec.storeAddr ? exec.n[0,$addrW+2$] : 32b0)
                    | (exec.storeVal  ? exec.val            : 32b0)
                    | (exec.load      ? loaded              : 32b0)
                    | (exec.intop     ? exec.r              : 32b0);

  // The 'always_before' block is applied at the start of every cycle.
  // This is a good place to set default values, which also indicates
  // to Silice that some variables (e.g. xregsA.wdata) are fully set
  // every cycle, enabling further optimizations.
  // Default values are overriden from within the algorithm loop.
  always {
    // decodes values loaded from memory (used when exec.load == 1)
    uint32 aligned <: mem.rdata >> {exec.n[0,2],3b000};
    switch ( exec.op[0,2] ) { // LB / LBU, LH / LHU, LW
      case 2b00:{ loaded = {{24{(~exec.op[2,1])&aligned[ 7,1]}},aligned[ 0,8]}; }
      case 2b01:{ loaded = {{16{(~exec.op[2,1])&aligned[15,1]}},aligned[ 0,16]};}
      case 2b10:{ loaded = aligned;   }
      default:  { loaded = {32{1bx}}; } // don't care (does not occur)
    }
    // what to write on a store (used when exec.store == 1)
    mem.wdata      = stage_0[1,1] ? (xregsB_0.rdata << {exec.n[0,2],3b000})
                                  : (xregsB_1.rdata << {exec.n[0,2],3b000});
    // maintain write enable low (pulses high when needed)
    mem.wenable    = 4b0000; 
    // maintain alu trigger low
    exec.trigger   = 0;
    // maintain register wenable low
    // (pulsed when necessary)
    xregsA_0.wenable = 0;
    xregsA_1.wenable = 0;


    // dual state machine
    // four states: F, T, LS1, LS2/commit
$$if SIMULATION then         
    __display("[cycle %d] stage_0:%b stage_1:%b",cycle,stage_0,stage_1);
$$end

    if ((stage_0 | stage_1) == 4b1010) {
        // one CPU on F, one CPU on LS1

        // F
        instr_0 = stage_0[3,1] ? mem.rdata : instr_0;
        pc_0    = stage_0[3,1] ? mem.addr  : pc_0;
        instr_1 = stage_1[3,1] ? mem.rdata : instr_1;
        pc_1    = stage_1[3,1] ? mem.addr  : pc_1;

$$if SIMULATION then         
        if (stage_0[3,1]) {
          __display("[cycle %d] (0) F instr_0:%h (@%h)",cycle,instr_0,pc_0<<2);
        } else {
          __display("[cycle %d] (1) F instr_1:%h (@%h)",cycle,instr_1,pc_1<<2);
        }
$$end

        // LS1
        // no need to know which CPU, since we only read from exec
        if (exec.load | exec.store) {   
          // memory address from which to load/store
          mem.addr    = exec.n >> 2;
          // == Store (enabled if exec.store == 1)
          // build write mask depending on SB, SH, SW
          // assumes aligned, e.g. SW => next_addr[0,2] == 2
          mem.wenable = ({4{exec.store}} & { { 2{exec.op[0,2]==2b10} },
                                                 exec.op[0,1] | exec.op[1,1], 1b1 
                                          } ) << exec.n[0,2];
$$if SIMULATION then         
          if (stage_0[1,1]) {
            __display("[cycle %d] (0) LS1 @%h = %h",cycle,mem.addr,mem.wdata);
          } else {
            __display("[cycle %d] (1) LS1 @%h = %h",cycle,mem.addr,mem.wdata);
          }
$$end          
        }

        // advance stage
        stage_0 = {stage_0[0,1],stage_0[1,3]};
        stage_1 = {stage_1[0,1],stage_1[1,3]};

      } else {
        
        // one CPU on T, one CPU on LS2/commit

        // T
        // triggers exec for the CPU which has been selected at F cycle before
        // registers are now in for it
        exec.trigger = 1;
        exec.cpu_id  = ~stage_0[2,1];
        exec.instr   = stage_0[2,1] ? instr_0 : instr_1;
        exec.pc      = stage_0[2,1] ? pc_0    : pc_1;
        exec.xa      = stage_0[2,1] ? xregsA_0.rdata : xregsA_1.rdata;
        exec.xb      = stage_0[2,1] ? xregsB_0.rdata : xregsB_1.rdata;

$$if SIMULATION then         
        if (stage_0[2,1]) {
          __display("[cycle %d] (0) T %h @%h xa[%d]=%h xb[%d]=%h",cycle,stage_0[2,1] ? instr_0 : instr_1,stage_0[2,1] ? pc_0    : pc_1,xregsA_0.addr,xregsA_0.rdata,xregsB_0.addr,xregsB_0.rdata);
        } else {
          __display("[cycle %d] (1) T %h @%h xa[%d]=%h xb[%d]=%h",cycle,stage_0[2,1] ? instr_0 : instr_1,stage_0[2,1] ? pc_0    : pc_1,xregsA_1.addr,xregsA_1.rdata,xregsB_1.addr,xregsB_1.rdata);
        }
$$end

        // LS2/commit

        // commit result
        xregsA_0.wenable = stage_0[0,1] ? ~exec.no_rd : 0;
        xregsA_1.wenable = stage_1[0,1] ? ~exec.no_rd : 0;
                        // ^^^^^^^^ could be ~stage_0[0,1]

$$if SIMULATION then         
        if (stage_0[0,1]) {
          if (xregsA_0.wenable) {
            __display("[cycle %d] (0) LS2/C xr[%d]=%h (alu:%h)",cycle,exec.write_rd,write_back,exec.r);
          }
        } else {
          if (xregsA_1.wenable) {
            __display("[cycle %d] (1) LS2/C xr[%d]=%h (alu:%h)",cycle,exec.write_rd,write_back,exec.r);
          }
        }
$$end
        // prepare instruction fetch
        mem.addr         = exec.jump ? (exec.n >> 2)
                                     : next_pc; // (stage_0[0,1] ? next_pc_0 : next_pc_1);

        // advance states unless stuck in ALU
        if (exec.working == 0) {
          stage_0 = {stage_0[0,1],stage_0[1,3]};
          stage_1 = {stage_1[0,1],stage_1[1,3]};
        }
$$if SIMULATION then               
        else {
          __display("[cycle %d] waiting for ALU",cycle);
        }
$$end        
      }

    // write back data to both register BRAMs
    xregsA_0.wdata   = write_back;      xregsB_0.wdata   = write_back;     
    xregsA_1.wdata   = write_back;      xregsB_1.wdata   = write_back;     
    // xregsB written when xregsA is
    xregsB_0.wenable = xregsA_0.wenable; 
    xregsB_1.wenable = xregsA_1.wenable; 
    // write to write_rd, else track instruction register
    xregsA_0.addr    = xregsA_0.wenable ? exec.write_rd : Rtype(instr_0).rs1;
    xregsB_0.addr    = xregsA_0.wenable ? exec.write_rd : Rtype(instr_0).rs2;
    xregsA_1.addr    = xregsA_1.wenable ? exec.write_rd : Rtype(instr_1).rs1;
    xregsB_1.addr    = xregsA_1.wenable ? exec.write_rd : Rtype(instr_1).rs2;
$$if SIMULATION then         
    cycle = cycle + 1;
$$end    
  }

}
