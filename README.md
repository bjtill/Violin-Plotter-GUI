# Violin-Plotter-GUI

This is a bash GUI tool to simplify the task of making custom violin plots with mean and standard deviation. The program takes user parameters and uses ggplot2 in R to make the plot.

INPUT: A data table in comma-separated values format with a header. Each column reprepsents a unique sample or trial. If technical or biological replicates are included, and you want to plot them together, the replicate data should share the same name in the header (see example data). 

PARAMETERS:
1. User initials (for log file)
2. Input file choice
3. Presence of replicates
4. Remove samples or change the sample order in the plot
5. X-axis label
6. Y-axis label
7. Plot title
8. Fill color for violin plot
9. Opacity of violin fill
10. Size of plotted dots
11. Fill color of dots
12. Outline color of dots
13. Opacity of dots
14. Color of mean and stdev bars
15. Opacity of mean and stdev bars
16. File format of saved plot
17. Resolution of saved plot

OUTPUTS: A violin plot of your data with your selected parameters in jpeg format, a copy of the original data table used for plotting, user-selected data formatted for plotting, and a log file that contains the R code for making the plot. 

DEPENDENCIES:  Bash, awk, zenity, yad, datamash, R, ggplot2(R), svglite(R)

NOTES:  Fill and outline colors of data points are automatically assigned when running in replicate mode.  This can sometimes result in similar colors being assigned to replicate data.  If this is an issue, simply change the column order of the replicates in the original data table. This software was tested on Linux Ubuntu 20.04  LTS, and should work on macOS as similar bash tools I have created have tested okay on mac.  Testing has not been done with Windows but  in theory you can install Linux bash shell on Windows (https://itsfoss.com/install-bash-on-windows/) and install the dependencies from the command line. If you try this and it works, please let me know. I don't have a Windows machine for testing.

EXAMPLE DATA: Example data can be found in the directory ViP_Example_Data. 

TO RUN: Launch in a terminal window using ./ A graphical window will appear with information. Click OK to start. When prompted, enter the name for your analysis directory. A new directory will be created and the files created will be deposited in the directory. Follow the prompts to select files and start the program.
