# 
# Synthesis run script generated by Vivado
# 

  set_param gui.test TreeTableDev
set_msg_config -id {HDL 9-1061} -limit 100000
set_msg_config -id {HDL 9-1654} -limit 100000
create_project -in_memory -part xc7k70tfbg676-1
set_property target_language VHDL [current_project]
set_param project.compositeFile.enableAutoGeneration 0
set_property constrs_type UCF [current_fileset -constrset]

read_ip d:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/project_1/project_1.srcs/sources_1/ip/dcm_recfg/dcm_recfg.xco
set_msg_config -id {IP_Flow 19-2162} -severity warning -new_severity info
set_property is_locked true [get_files d:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/project_1/project_1.srcs/sources_1/ip/dcm_recfg/dcm_recfg.xco]

read_ip d:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/project_1/project_1.srcs/sources_1/ip/dcm_fixed/dcm_fixed.xco
set_msg_config -id {IP_Flow 19-2162} -severity warning -new_severity info
set_property is_locked true [get_files d:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/project_1/project_1.srcs/sources_1/ip/dcm_fixed/dcm_fixed.xco]

read_verilog {
  D:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/ShiftReg_s.v
  D:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/hijacker.v
}
read_vhdl {
  D:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/iodrp_mcb_controller.vhd
  D:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/iodrp_controller.vhd
  D:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/mcb_soft_calibration.vhd
  D:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/mcb_soft_calibration_top.vhd
  D:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/mcb_raw_wrapper.vhd
  D:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/memc3_wrapper.vhd
  D:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/SysCon.vhd
  D:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/FBCtl.vhd
  D:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/CamCtl.vhd
  D:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/VmodCAM_Ref.vhd
}
read_vhdl -library digilent {
  D:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/remote_sources/_/lib/digilent/Video.vhd
  D:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/remote_sources/_/lib/digilent/TWICtl.vhd
  D:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/remote_sources/_/lib/digilent/TMDSEncoder.vhd
  D:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/remote_sources/_/lib/digilent/SerializerN_1.vhd
  D:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/remote_sources/_/lib/digilent/LocalRst.vhd
  D:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/remote_sources/_/lib/digilent/InputSync.vhd
  D:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/remote_sources/_/lib/digilent/VideoTimingCtl.vhd
  D:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/remote_sources/_/lib/digilent/DVITransmitter.vhd
}
set_property webtalk.parent_dir D:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/project_1/project_1.data/wt [current_project]
set_property parent.project_dir D:/Program/MYPRJ~1/HG_Sync/FPGA/fpgadisparity/DisPrj/source/project_1 [current_project]
synth_design -top VmodCAM_Ref -part xc7k70tfbg676-1
write_checkpoint VmodCAM_Ref.dcp
report_utilization -file VmodCAM_Ref_utilization_synth.rpt -pb VmodCAM_Ref_utilization_synth.pb