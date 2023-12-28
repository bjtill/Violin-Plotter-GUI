#!/bin/bash
#First version: Bradley Till Dec 12, 2023
#Designed to be a bash/R GUI tool to generate custom violin plots.  
#V1.1 Omission of data not working
#V1.2 Fixes user-chosen data omission Adds outline color control and dpi control.
zenity --width 1000 --info --title "Violin Plotter (ViP)" --text "
Version 1.2

ABOUT: A GUI interface to make custom violin plots using R.

INPUT: A data table in comma-separated values format with a header. Each column reprepsents a unique sample or trial. If technical or biological replicates are included, and you want to plot them together, the replicate data should share the same name in the header. For example:

Brad,Brad,Charlie,Suzie
3,2,3,4
2,2,4,4
4,2,1,1

OUTPUTS: A violin plot of your data with your selected parameters in jpeg format, a copy of the original data table used for plotting, user-selected data formatted for plotting, and a log file that contains the R code for making the plot. 

LICENSE:  
MIT License
Copyright (c) 2023 Bradley John Till
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the *Software*), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

DEPENDENCIES:  Bash, awk, zenity, yad, datamash, R, ggplot2(R), svglite(R)
VERSION INFORMATION: Dec 26, 2023 BT"

directory=`zenity --width 500 --title="DIRECTORY" --text "Enter text to create a new directory (e.g. Brad_Jan06_2024_plot1).  
WARNING: No spaces or symbols other than an underscore." --entry`

if [ "$?" != 0 ]
then
    exit
    fi
mkdir $directory
cd $directory
#Get Parameters
YADINPUT=$(yad --width=400 --title="ViP PARAMETERS" --text="CAUTION: Avoid the use of | and $ as these are special symbols for this program." --form --field="Your Initials" --form --item-separator="," --field="SELECT THE COMMA SEPARATED DATA":FL --field="Does your data contain replicates? (replicate columns should have the same name)":CB --field="Do you want to remove any samples, or control the order of their plotting? ":CBE "" "" "NO,YES" "NO,YES" --field="X-axis label (click to change)" "Sample" --field="Y-axis label (click to change)" "Value" --field="Plot title (click to change)" "Data" --field="Color of fill in violin (click to change)":CLR "cadetblue" --field="Opacity of violin fill (click to change)" "0.5" --field="Size of plotted dots (click to change)" "0.4" --field="Fill color of dots. NOTE: color is dynamically assigned when replicates are present. (click to change)":CLR "gray" --field="Outline color of dots. NOTE: color is dynamically assigned when replicates are present. (click to change)":CLR "gray" --field="Opacity of dots (click to change)" "0.3" --field="Color of mean and stdev bars (click to change)":CLR "firebrick" --field="Opacity mean and stdev bars (click to change)" "0.7" --field="Select format to save plot:CB" 'jpeg,tiff,png,svg,bmp' --field="Resolution of plot in dots per inch (click to change)" "300")
 echo $YADINPUT >> yad1
 datamash transpose --field-separator='|' < yad1 > yad2
 #Get data
 a=$(awk 'NR==2 {print $1}' yad2)
 echo "cp" ${a} "./UserDataP" > mover.sh
 chmod +x mover.sh
 ./mover.sh
 #Attempt to fix weird formatting that can come from spreadsheet software. 
 tr -d '\r' < UserDataP | tr -d '\15\32' > UserData
 rm UserDataP
 #Determine if replicates
 awk 'NR==3 {print $1}' yad2 > repanswer
 for file in repanswer
do
   # Avoid renaming diretories!
   if [ -f "$file" ]
   then
       newname=`head -1 $file`
       if [ -f "$newname" ]
       then
              echo "Cannot rename $file to $newname - file already exists"
       else
              mv "$file" "$newname".repanswer
       fi
   fi
done
 
  awk 'NR==4 {print $1}' yad2 > sampleanswer
 for file in sampleanswer
do
   # Avoid renaming diretories!
   if [ -f "$file" ]
   then
       newname=`head -1 $file`
       if [ -f "$newname" ]
       then
              echo "Cannot rename $file to $newname - file already exists"
       else
              mv "$file" "$newname".sampleanswer
       fi
   fi
done
#If the user wants to omit samples or change the order, a new window pops up.
if [ -f "YES.sampleanswer" ] ;

   then
#Create YAD dialog, deal with replicates and launch
printf '#/bin/bash \nYADOUT=$(yad --width=1000 --title="Use numbers to order the samples. If blank the sample will be omitted from plots." --form ' > top
head -1 UserData | tr ',' '\t' | datamash transpose | awk '!visited[$1]++' | awk '{print "--field=\x22"$1"\x22"}' | datamash transpose | tr '\t' ' ' > mid
echo ")"  > end
printf 'echo $YADOUT >> yadout' > end2
paste mid end | tr '\t' ' ' | cat top - | cat - end2 > choice.sh
chmod +x choice.sh
./choice.sh
#Create a sample list in the order to plot
tr '|' '\t' < yadout | datamash transpose | head -n -1 | awk '{if ($1<1) print "0"; else print $0}' > sortorder #Note that with yad you get a terminal blank row which is removed. If no value is provided, the sample gets a zero
head -1 UserData | tr ',' '\t' | datamash transpose | awk '!visited[$1]++' > startinglist
#Make a file for logging
paste sortorder startinglist | sort -n -k1,1 > ORDER_REMOVED
paste sortorder startinglist | awk '{if($1>0) print $0}' | sort -n -k1,1 | awk '{print $2}' > sampleplotorder
fi 

zenity --width 400 --info --title "READY TO LAUNCH" --text "Click OK to start the violin plotter"
if [ "$?" != 0 ]
then
    exit
fi
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>GBBt.log 2>&1
now=$(date)  
echo "Violin Plotter (ViP) Version 1.2
Script Started $now."  

(#Starting
echo "# Beginning program"; sleep 2 

#No replicates no change in order or sample number
if [ -f NO.sampleanswer ] && [ -f NO.repanswer ] ; 
then

echo "5"
echo "# Formatting data"; sleep 2
awk -F, '{for(i=1; i<=NF; i++) print $i >> "column" i ".splot"}' UserData
for i in *.splot; do 
a=$(head -1 $i) 
tail -n +2 $i | awk -v var=$a '{print $1, var}' > ${i%.*}.sploot; done 
rm *.splot 
cat *.sploot | awk -v var=$b 'BEGIN{print "Value", "Sample"}1' | tr ' ' ',' > FormattedData4plot.csv
rm *.sploot

echo "45"
echo "# Generating plot"; sleep 2


a=$(awk 'NR==5 {print $0}'  yad2 | tr ' ' '$' )
b=$(awk 'NR==6 {print $0}' yad2 | tr ' ' '$' )
c=$(awk 'NR==7 {print $0}' yad2 | tr ' ' '$' )
d=$(awk 'NR==8 {print $0}' yad2)
e=$(awk 'NR==9 {print $0}' yad2)
g=$(awk 'NR==10 {print $0}' yad2)
h=$(awk 'NR==11 {print $0}' yad2)
i=$(awk 'NR==13 {print $0}' yad2)
j=$(awk 'NR==14 {print $0}' yad2)
k=$(awk 'NR==15 {print $0}' yad2)
l=$(awk 'NR==7 {print $0}' yad2 | tr ' ' '_' )
m=$(date +%F)
o=$(awk 'NR==16 {print $0}' yad2)
p=$(awk 'NR==12 {print $0}' yad2) 
q=$(awk 'NR==17 {print $0}' yad2)
printf 'library(ggplot2) \ndata<-read.csv("FormattedData4plot.csv")\np <- ggplot(data, aes(x=Sample, y=Value)) + geom_violin(trim=FALSE, fill="%s", alpha=%s) + geom_dotplot(binaxis="y", stackdir="center", dotsize=%s, fill="%s", color="%s", alpha=%s) + labs(title= "%s") + xlab("%s") + ylab("%s")\ndata_summary <- function(x) { \nm <- mean(x) \nymin <- m-sd(x) \nymax <- m+sd(x) \nymax <- m+sd(x) \nreturn(c(y=m,ymin=ymin,ymax=ymax)) \n} \np1 <- p + stat_summary(fun.data=data_summary, color="%s", geom = "pointrange", alpha=%s) \nggsave(plot = p1, dpi=%s, filename= "%s_%s.%s")' $d $e $f $g $h $p $i $c $a $b $j $k $q $l $m $o | tr '$' ' ' > plotter.R
Rscript plotter.R 
echo "90"

fi 
#replicates but no sample order
if [ -f NO.sampleanswer ] && [ -f YES.repanswer ] ; 
then

echo "5"
echo "# Formatting data"; sleep 2
awk -F, '{for(i=1; i<=NF; i++) print $i >> "column" i ".splot"}' UserData
for i in *.splot; do 
a=$(head -1 $i) 
tail -n +2 $i | awk -v var=$a '{print $1, var}' > ${i%.*}.sploota
awk '{print $0, FILENAME}' ${i%.*}.sploota | sed 's/column//g' | sed 's/.sploota//g' > ${i%.*}.sploot ; done 
rm *.splot *.sploota
cat *.sploot | awk -v var=$b 'BEGIN{print "Value", "Sample", "Trial"}1' | tr ' ' ',' > FormattedData4plot.csv
rm *.sploot 

echo "45"
echo "# Generating plot"; sleep 2

a=$(awk 'NR==5 {print $0}'  yad2 | tr ' ' '$' )
b=$(awk 'NR==6 {print $0}' yad2 | tr ' ' '$' )
c=$(awk 'NR==7 {print $0}' yad2 | tr ' ' '$' )
d=$(awk 'NR==8 {print $0}' yad2)
e=$(awk 'NR==9 {print $0}' yad2)
g=$(awk 'NR==10 {print $0}' yad2)
h=$(awk 'NR==11 {print $0}' yad2)
i=$(awk 'NR==13 {print $0}' yad2)
j=$(awk 'NR==14 {print $0}' yad2)
k=$(awk 'NR==15 {print $0}' yad2)
l=$(awk 'NR==7 {print $0}' yad2 | tr ' ' '_' )
m=$(date +%F)
o=$(awk 'NR==16 {print $0}' yad2)
p=$(awk 'NR==12 {print $0}' yad2) 
q=$(awk 'NR==17 {print $0}' yad2)
printf 'library(ggplot2) \ndata<-read.csv("FormattedData4plot.csv")\np <- ggplot(data, aes(x=Sample, y=Value)) + geom_violin(trim=FALSE, fill="%s", alpha=%s) + geom_dotplot(binaxis="y", stackdir="center", dotsize=%s, aes(fill = factor(Trial)),  alpha=%s) + labs(title= "%s", fill="Experiment\n") + xlab("%s") + ylab("%s")\ndata_summary <- function(x) { \nm <- mean(x) \nymin <- m-sd(x) \nymax <- m+sd(x) \nymax <- m+sd(x) \nreturn(c(y=m,ymin=ymin,ymax=ymax)) \n} \np1 <- p + stat_summary(fun.data=data_summary, color="%s", geom = "pointrange", alpha=%s) \nggsave(plot = p1, dpi=%s, filename= "%s_%s.%s")' $d $e $g $i $c $a $b $j $k $q $l $m $o | tr '$' ' ' > plotter.R
Rscript plotter.R 
echo "90"

fi 

##both replicates and sample order  
if [ -f YES.sampleanswer ] && [ -f YES.repanswer ] ; 
then
echo "5"
echo "# Formatting data"; sleep 2

awk '{print "\x22"$1"\x22,"}' sampleplotorder | datamash transpose | awk '{print substr($0, 1, length($0)-1)}' | tr '\t' '$' > p2

awk -F, '{for(i=1; i<=NF; i++) print $i >> "column" i ".splot"}' UserData
for i in *.splot; do 
a=$(head -1 $i) 
tail -n +2 $i | awk -v var=$a '{print $1, var}' > ${i%.*}.sploota
awk '{print $0, FILENAME}' ${i%.*}.sploota | sed 's/column//g' | sed 's/.sploota//g' > ${i%.*}.sploot ; done 
rm *.splot *.sploota
cat *.sploot | grep -wFf sampleplotorder - | awk -v var=$b 'BEGIN{print "Value", "Sample", "Trial"}1' | tr ' ' ',' > FormattedData4plot.csv
rm *.sploot 

echo "45"
echo "# Generating plot"; sleep 2
a=$(awk 'NR==5 {print $0}'  yad2 | tr ' ' '$' )
b=$(awk 'NR==6 {print $0}' yad2 | tr ' ' '$' )
c=$(awk 'NR==7 {print $0}' yad2 | tr ' ' '$' )
d=$(awk 'NR==8 {print $0}' yad2)
e=$(awk 'NR==9 {print $0}' yad2)
g=$(awk 'NR==10 {print $0}' yad2)
h=$(awk 'NR==11 {print $0}' yad2)
i=$(awk 'NR==13 {print $0}' yad2)
j=$(awk 'NR==14 {print $0}' yad2)
k=$(awk 'NR==15 {print $0}' yad2)
l=$(awk 'NR==7 {print $0}' yad2 | tr ' ' '_' )
m=$(date +%F)
n=$(awk '{print $1}' p2)
o=$(awk 'NR==16 {print $0}' yad2)
p=$(awk 'NR==12 {print $0}' yad2) 
q=$(awk 'NR==17 {print $0}' yad2)
printf 'library(ggplot2) \ndata<-read.csv("FormattedData4plot.csv")\np <- ggplot(data, aes(x=factor(Sample, level=c(%s)), y=Value)) + geom_violin(trim=FALSE, fill="%s", alpha=%s) + geom_dotplot(binaxis="y", stackdir="center", dotsize=%s, aes(fill = factor(Trial)),  alpha=%s) + labs(title= "%s", fill="Experiment") + xlab("%s") + ylab("%s") \ndata_summary <- function(x) { \nm <- mean(x) \nymin <- m-sd(x) \nymax <- m+sd(x) \nymax <- m+sd(x) \nreturn(c(y=m,ymin=ymin,ymax=ymax)) \n} \np1 <- p + stat_summary(fun.data=data_summary, color="%s", geom = "pointrange", alpha=%s) \nggsave(plot = p1, dpi=%s, filename= "%s_%s.%s")' $n $d $e $g $i $c $a $b $j $k $q $l $m $o | tr '$' ' ' > plotter.R
Rscript plotter.R 
echo "90"

fi 

##No replicates but sample order

if [ -f YES.sampleanswer ] && [ -f NO.repanswer ] ; 
then
echo "5"
echo "# Formatting data"; sleep 2


awk '{print "\x22"$1"\x22,"}' sampleplotorder | datamash transpose | awk '{print substr($0, 1, length($0)-1)}' | tr '\t' '$' > p2

awk -F, '{for(i=1; i<=NF; i++) print $i >> "column" i ".splot"}' UserData
for i in *.splot; do 
a=$(head -1 $i) 
tail -n +2 $i | awk -v var=$a '{print $1, var}' > ${i%.*}.sploot; done 
rm *.splot 
cat *.sploot | grep -wFf sampleplotorder - | awk -v var=$b 'BEGIN{print "Value", "Sample"}1' | tr ' ' ',' > FormattedData4plot.csv
rm *.sploot

echo "45"
echo "# Generating plot"; sleep 2
a=$(awk 'NR==5 {print $0}'  yad2 | tr ' ' '$' )
b=$(awk 'NR==6 {print $0}' yad2 | tr ' ' '$' )
c=$(awk 'NR==7 {print $0}' yad2 | tr ' ' '$' )
d=$(awk 'NR==8 {print $0}' yad2)
e=$(awk 'NR==9 {print $0}' yad2)
g=$(awk 'NR==10 {print $0}' yad2)
h=$(awk 'NR==11 {print $0}' yad2)
i=$(awk 'NR==13 {print $0}' yad2)
j=$(awk 'NR==14 {print $0}' yad2)
k=$(awk 'NR==15 {print $0}' yad2)
l=$(awk 'NR==7 {print $0}' yad2 | tr ' ' '_' )
m=$(date +%F)
n=$(awk '{print $1}' p2)
o=$(awk 'NR==16 {print $0}' yad2)
p=$(awk 'NR==12 {print $0}' yad2) 
q=$(awk 'NR==17 {print $0}' yad2)
printf 'library(ggplot2) \ndata<-read.csv("FormattedData4plot.csv")\np <- ggplot(data, aes(x=factor(Sample, level=c(%s)), y=Value)) + geom_violin(trim=FALSE, fill="%s", alpha=%s) + geom_dotplot(binaxis="y", stackdir="center", dotsize=%s, fill="%s", color="%s",  alpha=%s) + labs(title= "%s", fill="Experiment") + xlab("%s") + ylab("%s") \ndata_summary <- function(x) { \nm <- mean(x) \nymin <- m-sd(x) \nymax <- m+sd(x) \nymax <- m+sd(x) \nreturn(c(y=m,ymin=ymin,ymax=ymax)) \n} \np1 <- p + stat_summary(fun.data=data_summary, color="%s", geom = "pointrange", alpha=%s) \nggsave(plot = p1, dpi=%s, filename= "%s_%s.%s")' $n $d $e $g $h $p $i $c $a $b $j $k $q $l $m $o | tr '$' ' ' > plotter.R
Rscript plotter.R 


echo "90"

fi 
echo "95"
echo "# Tidying"; sleep 2
printf 'Initials of user: \nLocation and name of data file: \n User-defined replicates: \n User changed samples or order: \nX-axis label:  \nY-axis label: \nPlot title: \n Plot fill color: \nOpacity of plot fill: \nSize of dots: \nFill olor of dots if available: \nOutline color of dots if available: \nOpacity of dots: \nColor of mean and stdev bars: \nOpacity of mean and stdev bars: \nFormat of saved plot: \nDPI of saved plot:' > log1
paste log1 yad2 | tr '\t' ' ' | awk 'BEGIN{print "User-selected plotting parameters:"}1' > log2
awk 'BEGIN{print "R code used to make the plot:"}1' plotter.R > plotcode
a=$(date +%F)
grep -v "Pick better value" GBBt.log > loga #issue loosing finish time when piped 
cat loga log2 | cat - plotcode > ViP_${a}.log
rm GBBt.log mover.sh *.repanswer *.sampleanswer plotter.R yad1 yad2 end end3 mid p2 sampleplotorder sortorder startinglist top yadout plotcode end2 log1 log2 choice.sh loga
mv ORDER_REMOVED User_Selected_Samples_and_Order_${a}.txt
mv UserData User_Selected_Data_Table_${a}.csv

) | zenity --width 800 --title "PROGRESS" --progress --auto-close
now=$(date)
echo "Script Finished $now."

#END OF PROGRAM

