#
#setenv LD_LIBRARY_PATH /usr/cad/synopsys/verdi/2020.03/share/PLI/VCS/linux64:$LD_LIBRARY_PATH
#VCS_fsdb_path := /usr/cad/synopsys/verdi/2020.03/share/PLI/VCS/linux64/novas.tab\
	 /usr/cad/synopsys/verdi/2020.03/share/PLI/VCS/linux64/pli.a
#===========================================================================================#
#define
Pattern := L2_SNR1
#
File := Top_syn
#File := Top_syn_spg
#File := Top_apr
#
#filelist := filelist_cg.f
#filelist.f,filelist_cg.f
#filelist := filelist_v18.f
filelist := filelist_v19.f
#
TN40G_sim_path := /cad/CBDK/CBDK_TN40G_Arm/CBDK_TSMC40_core_Arm_v2.0/CIC/Verilog
TN40G_sim_hvt := $(TN40G_sim_path)/sc9_cln40g_base_hvt_neg.v
TN40G_sim_hvt_udp := $(TN40G_sim_path)/sc9_cln40g_base_hvt_udp.v
TN40G_sim_lvt := $(TN40G_sim_path)/sc9_cln40g_base_lvt_neg.v
TN40G_sim_lvt_udp := $(TN40G_sim_path)/sc9_cln40g_base_lvt_udp.v
TN40G_sim_rvt := $(TN40G_sim_path)/sc9_cln40g_base_rvt_neg.v
TN40G_sim_rvt_udp := $(TN40G_sim_path)/sc9_cln40g_base_rvt_udp.v
TN40G_sim := -v ./Simulation_file/sc9_cln40g_base_hvt_neg.v \
	-v ./Simulation_file/sc9_cln40g_base_hvt_udp.v \
	-v ./Simulation_file/sc9_cln40g_base_lvt_neg.v \
	-v ./Simulation_file/sc9_cln40g_base_lvt_udp.v \
	-v ./Simulation_file/sc9_cln40g_base_rvt_neg.v \
	-v ./Simulation_file/sc9_cln40g_base_rvt_udp.v
#
COV_OPT := line+cond+fsm+tgl
#===========================================================================================#
#2 step flow
rtl_2step:#cg: filelist_cg.f
	Rvcs -R ./TB/Top_tb.v -f $(filelist) +define+$(Pattern) -full64 -v2005 +v2k | tee ./log/rtl_sim.log
rtl_2step_vcd:#cg: filelist_cg.f
	Rvcs -R ./TB/Top_tb.v -f $(filelist) +define+$(Pattern) +define+VCD -full64 -v2005 +v2k | tee ./log/rtl_sim.log
rtl_2step_fsdb:#cg: filelist_cg.f
	Rvcs -R ./TB/Top_tb.v -f $(filelist) +define+$(Pattern) +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+Waveform.fsdb -full64 -v2005 +v2k | tee ./log/rtl_sim.log
#
#3 step flow
#rtl_debug: rtl_ana_debug rtl_comp_debug rtl_sim_debug
#rtl_ana_debug:
#	vlogan TB/Top_Debug_tb.v -f filelist.f -full64 -v2005 +v2k
#rtl_comp_debug:
#	vcs  TB/Top_Debug_tb.v -f filelist.f -full64 -v2005 +v2k
#rtl_sim_debug:
#	./simv
rtl_3step: rtl_ana rtl_comp rtl_sim rtl_cov
rtl_ana:
	vlogan ./TB/Top_tb.v -f $(filelist) +define+$(Pattern) -full64 -v2005 +v2k | tee ./log/rtl_sim.log
rtl_comp:
	vcs  ./TB/Top_tb.v -f $(filelist) +define+$(Pattern) -full64 -v2005 +v2k -cm $(COV_OPT) | tee ./log/rtl_sim.log
rtl_sim:
	./simv -cm $(COV_OPT)
rtl_cov:
	urg -dir simv.vdb -report both_Top
#===========================================================================================#
#copy simulation file to local
copy_simulation_file:
	cp $(TN40G_sim_hvt) ./Simulation_file/
	cp $(TN40G_sim_hvt_udp) ./Simulation_file/
	cp $(TN40G_sim_lvt) ./Simulation_file/
	cp $(TN40G_sim_lvt_udp) ./Simulation_file/
	cp $(TN40G_sim_rvt) ./Simulation_file/
	cp $(TN40G_sim_rvt_udp) ./Simulation_file/
#gate-level simulation
syn_sim:#2 macro: Pattern and File
	Rvcs @ver 1 -R ./TB/Top_postsim_tb.v ./Output/$(File).v $(TN40G_sim) +define+$(Pattern) +define+$(File) +sdfverbose -full64 \
	| tee ./log/syn_sim_$(Pattern).log
syn_sim_ntc:#2 macro: Pattern and File
	Rvcs @ver 1 -R ./TB/Top_postsim_tb.v ./Output/$(File).v $(TN40G_sim) +define+$(Pattern) +define+$(File) +sdfverbose +notimingcheck -full64 \
	| tee ./log/syn_sim_$(Pattern).log
syn_sim_vcd:#2 macro: Pattern and File
	Rvcs @ver 1 -R ./TB/Top_postsim_tb.v ./Output/$(File).v $(TN40G_sim) +define+$(Pattern) +define+$(File) +sdfverbose +define+VCD -full64 \
	| tee ./log/syn_sim_$(Pattern).log
syn_sim_fsdb:#2 macro: Pattern and File
	Rvcs @ver 1 -R ./TB/Top_postsim_tb.v ./Output/$(File).v $(TN40G_sim) +define+$(Pattern) +define+$(File) +sdfverbose -full64 \
	+access+r +vcs+fsdbon +fsdb+mda +fsdbfile+$(Pattern).fsdb \
	| tee ./log/syn_sim_$(Pattern).log
syn_sim_vcd_ntc:#2 macro: Pattern and File
	Rvcs @ver 1 -R ./TB/Top_postsim_tb.v ./Output/$(File).v $(TN40G_sim) +define+$(Pattern) +define+$(File) +sdfverbose +define+VCD +notimingcheck -full64 \
	| tee ./log/syn_sim_$(Pattern).log
#dft
post_sim_dft:#2 macro: Pattern and File
	Rvcs @ver 1 -R ./TB/Top_postsim_tb.v ./Output/$(File).v $(TN40G_sim) +define+$(Pattern) +define+$(File) +sdfverbose +define+DFT +neg_tclk -full64 \
	| tee ./log/post_sim_dft_$(File)_$(Pattern).log
post_sim_dft_ntc:#2 macro: Pattern and File
	Rvcs @ver 1 -R ./TB/Top_postsim_tb.v ./Output/$(File).v $(TN40G_sim) +define+$(Pattern) +define+$(File) +sdfverbose +define+DFT +notimingcheck -full64 \
	| tee ./log/post_sim_dft_$(File)_$(Pattern).log
post_sim_dft_vcd:#2 macro: Pattern and File
	Rvcs @ver 1 -R ./TB/Top_postsim_tb.v ./Output/$(File).v $(TN40G_sim) +define+$(Pattern) +define+$(File) +sdfverbose +define+DFT +neg_tclk +define+VCD -full64 \
	| tee ./log/post_sim_dft_$(File)_$(Pattern).log
post_sim_dft_fsdb:#2 macro: Pattern and File
	Rvcs @ver 1 -R ./TB/Top_postsim_tb.v ./Output/$(File).v $(TN40G_sim) +define+$(Pattern) +define+$(File) +sdfverbose +define+DFT +neg_tclk -full64 \
	+access+r +vcs+fsdbon +fsdb+mda +fsdbfile+$(Pattern).fsdb \
	| tee ./log/post_sim_dft_$(File)_$(Pattern).log
post_sim_dft_vcd_ntc:#2 macro: Pattern and File
	Rvcs @ver 1 -R ./TB/Top_postsim_tb.v ./Output/$(File).v $(TN40G_sim) +define+$(Pattern) +define+$(File) +sdfverbose +define+DFT +define+VCD +notimingcheck -full64 \
	| tee ./log/post_sim_dft_$(File)_$(Pattern).log
#===========================================================================================#
#ndm_gen.tcl
ndm_gen:
	Ricc2_lm_shell -f ./Scripts/ndm_gen.tcl | tee ./log/ndm_gen.log
#===========================================================================================#
#syn
syn:
	Rdcnxt_shell -topo -f ./Scripts/syn.tcl | tee ./log/syn.log
syn_normal:
	Rdc_shell -f ./Scripts/syn_normal.tcl | tee ./log/syn_normal.log
#===========================================================================================#
#pt
pt:
	Rpt_shell -f ./Scripts/pt.tcl | tee ./log/pt.log
#===========================================================================================#
#clean
clean:
	rm -r *.mr *.pvl *.syn *.log *.txt *.ems *.key sdfAnnotateInfo \
	alib-52/ simv.daidir/ csrc/  simv *novas *.tcl *default* *icc*