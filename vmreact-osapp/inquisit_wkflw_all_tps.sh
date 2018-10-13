#!/bin/bash


## needs python 2.7, panda, numpy
#path definitions
grader_script="/Users/lillyel-said/Desktop/stanford/scripts/inquisit/final/argparse"
inquisit_dir='/Volumes/quincy/inquisit/'
data_output_path="${inquisit_dir}/inquisit_task"
tp1_script_path="${inquisit_dir}/inquisit_task/task_script"
tp2_script_path="${inquisit_dir}/inquisit_task/task_script_by_form"


#variable assignments
list_types=($(seq 1 1 4))
subj_id=$1
timepoint=$2
initial_list=$3

dir_id=best_${subj_id}_tp${timepoint}
main_dir_id=best_${subj_id}_tp${timepoint}_inquisit
full_subj_path=${data_output_path}/participant_data/${main_dir_id}
log_file=${full_subj_path}/out/log.txt

#makes data directories
cd ${data_output_path}/participant_data
mkdir ${full_subj_path};
mkdir ${full_subj_path}/csv ${full_subj_path}/raw ${full_subj_path}/out;

#runs the inquisit script
cd ${full_subj_path};
if [ ${timepoint} == 1 ]; then
	/Applications/Inquisit\ 5.app/Contents/MacOS/Inquisit\ 5 ${tp1_script_path}/rey_ant_pt_hv_version_all_lists_17_08_01.iqx -s ${subj_id} -g 1 >> /dev/null 2>&1;
else
	unset list_types[$initial_list-1]
    list_types=(${list_types[@]})
	tp2_list=${list_types[$(( RANDOM % 3))]}
	/Applications/Inquisit\ 5.app/Contents/MacOS/Inquisit\ 5 ${tp2_script_path}/rey_ant_pt_hv_version_form${tp2_list}_17_10_11.iqx -s ${subj_id} -g 1 >> /dev/null 2>&1;
fi
echo "inquisit file finished " >> ${log_file} 2>&1;
sleep 10

#organizes data
cd $data_output_path;
rsync -ap --progress ${data_output_path}/*/*_${subj_id}_*.iqdat ${data_output_path}/participant_data/${main_dir_id}/raw/ >> ${log_file} 2>&1;
cp -v ${full_subj_path}/raw/* ${full_subj_path}/csv/ >> ${log_file} 2>&1;
mv -v ${data_output_path}/task_scrip*/*_${subj_id}_*.iqdat ${data_output_path}/all_data >> ${log_file} 2>&1;

# renames the data
cd  ${full_subj_path}/csv;
mv -v `ls *demographics*` ${dir_id}_demographics_survey.iqdat >> ${log_file} 2>&1;
mv -v `ls *rey_ant_survey_survey*` ${dir_id}_rey_ant_survey.iqdat >> ${log_file} 2>&1;
mv -v `ls *_raw_*` ${dir_id}_raw.iqdat >> ${log_file} 2>&1;
mv -v `ls *_summary_*` ${dir_id}_summary.iqdat >> ${log_file} 2>&1;

#converts to csv from tab-delimited
for iqdat in `ls *.iqdat`;
	do
	cat $iqdat | tr "\\t" "," > `echo $iqdat | cut -d. -f1`.csv;
done

#grades the data
cd ${full_subj_path}/csv;
echo "grading output located at ${full_subj_path}/out" >> ${log_file} 2>&1;
python ${grader_script}/complete_inquisit_output.py -r `ls *raw.csv` -d `ls *demo*.csv` -s `ls *summary.csv*` -o ${full_subj_path}/out
