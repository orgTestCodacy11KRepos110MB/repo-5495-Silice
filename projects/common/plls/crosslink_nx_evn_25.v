module pll (
	input clki_i,
	input rst_i,
	output clkop_o,
	output lock_o
);

	PLL #(
		.CLKOP_TRIM("0b0000"),
		.TRIMOP_BYPASS_N("BYPASSED"),
		.DELA("33"),
		.DIVA("33"),
		.ENCLK_CLKOP("ENABLED"),
		.PHIA("0"),
		.SEL_OUTA("DISABLED"),
		.CLKOS_TRIM("0b0000"),
		.TRIMOS_BYPASS_N("BYPASSED"),
		.DELB("7"),
		.DIVB("7"),
		.ENCLK_CLKOS("ENABLED"),
		.PHIB("0"),
		.SEL_OUTB("DISABLED"),
		.DELC("7"),
		.DIVC("7"),
		.ENCLK_CLKOS2("ENABLED"),
		.PHIC("0"),
		.SEL_OUTC("DISABLED"),
		.DELD("7"),
		.DIVD("7"),
		.ENCLK_CLKOS3("ENABLED"),
		.PHID("0"),
		.SEL_OUTD("DISABLED"),
		.DELE("7"),
		.DIVE("7"),
		.ENCLK_CLKOS4("ENABLED"),
		.PHIE("0"),
		.SEL_OUTE("DISABLED"),
		.DELF("7"),
		.DIVF("7"),
		.ENCLK_CLKOS5("ENABLED"),
		.PHIF("0"),
		.SEL_OUTF("DISABLED"),
		.SSC_EN_SDM("DISABLED"),
		.DIRECTION("DISABLED"),
		.DYN_SEL("0b000"),
		.DYN_SOURCE("STATIC"),
		.ENABLE_SYNC("DISABLED"),
		.PLLPDN_EN("DISABLED"),
		.FBK_INTEGER_MODE("ENABLED"),
		.FBK_MASK("0b00000000"),
		.FBK_MMD_DIG("2"),
		.LDT_LOCK_SEL("UFREQ"),
		.LEGACY_ATT("DISABLED"),
		.LOAD_REG("DISABLED"),
		.OPENLOOP_EN("DISABLED"),
		.PLLPD_N("USED"),
		.PLLRESET_ENA("ENABLED"),
		.REF_INTEGER_MODE("ENABLED"),
		.REF_MASK("0b00000000"),
		.REF_MMD_DIG("1"),
		.ROTATE("DISABLED"),
		.SSC_EN_SSC("DISABLED"),
		.REF_MMD_PULS_CTL("0b0000"),
		.FBK_MMD_PULS_CTL("0b0000"),
		.V2I_PP_ICTRL("0b11111"),
		.SEL_FBK("FBKCLK0"),
		.CLKMUX_FB("CMUX_CLKOP"),
		.KP_VCO("0b00011"),
		.CSET("64P"),
		.CRIPPLE("1P"),
		.IPP_CTRL("0b1000"),
		.IPP_SEL("0b0001"),
		.BW_CTL_BIAS("0b1101"),
		.IPI_CMPN("0b0011"),
		.IPI_CMP("0b0001"),
		.V2I_PP_RES("9P3K"),
		.V2I_KVCO_SEL("60"),
		.V2I_1V_EN("ENABLED"),
		.SSC_N_CODE("0b000000010"),
		.SSC_F_CODE("0b000000000000000"),
		.EXTERNAL_DIVIDE_FACTOR("1"))
	u0_PLL (
		.INTFBKOP(),
		.INTFBKOS(),
		.INTFBKOS2(),
		.INTFBKOS3(),
		.INTFBKOS4(),
		.INTFBKOS5(),
		.DIR(1'b1),
		.DIRSEL(3'b111),
		.LOADREG(1'b1),
		.DYNROTATE(1'b1),
		.LMMICLK(1'b1),
		.LMMIRESET_N(1'b1),
		.LMMIREQUEST(1'b1),
		.LMMIWRRD_N(1'b1),
		.LMMIOFFSET(7'b1111111),
		.LMMIWDATA(8'b11111111),
		.LMMIRDATA(),
		.LMMIRDATAVALID(),
		.LMMIREADY(),
		.PLLPOWERDOWN_N(1'b0),
		.REFCK(clki_i),
		.CLKOP(clkop_o),
		.CLKOS(),
		.CLKOS2(),
		.CLKOS3(),
		.CLKOS4(),
		.CLKOS5(),
		.ENCLKOP(1'b1),
		.ENCLKOS(1'b1),
		.ENCLKOS2(1'b1),
		.ENCLKOS3(1'b1),
		.ENCLKOS4(1'b1),
		.ENCLKOS5(1'b1),
		.FBKCK(clkop_o),
		.INTLOCK(),
		.LEGACY(1'b1),
		.LEGRDYN(),
		.LOCK(lock_o),
		.PFDDN(),
		.PFDUP(),
		.PLLRESET(rst_i),
		.STDBY(1'b0),
		.REFMUXCK(),
		.REGQA(),
		.REGQB(),
		.REGQB1(),
		.CLKOUTDL(),
		.ROTDEL(1'b0),
		.DIRDEL(1'b0),
		.ROTDELP1(1'b0),
		.GRAYTEST(5'b0),
		.BINTEST(2'b0),
		.DIRDELP1(1'b0),
		.GRAYACT(5'b0),
		.BINACT(2'b0)
	);
endmodule
