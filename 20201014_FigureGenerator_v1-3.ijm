/*
 * ImageJ Figure Generator v1.0
 * Rebecca Senft
 * July 17 2020
 * 
 * Instructions:
 * 
 * PLEASE READ
 * 
 * Upon running, ImageJ will ask you to select the location to store output images. 
 * Then user selects a single image that is currently open and adjusted to their liking. 
 * 
 * Images need to be single pane for this to work 
 * 
 * The macro will save versions of the selected image in grayscale and merges for figure presentation
 * The macro also saves a log file with the current B&C adjustments, image name, and other optional parameters entered by the user

 * User can select the LUTs or leave them as they currently are.  
 * 
 * Please report any errors or crashes you get to Rebecca Senft (senftrebecca@gmail.com)
 * 
 * Version history
 * Version 1.1: fixed issue with a crash when a scale bar was not selected.
 * Version 1.2: added a smaller scale bar size for very small images.
 * Version 1.3: Fixed issue with incorrectly selecting channel to apply LUT
 */

//***********************************************	
//Step 1. Select directory to save images and produce list of open images to process
//***********************************************	
print("\\Clear");
date=getDate(); 
saveType="Tiff";
dirSave= getDirectory("Choose a Directory to Save Images");
allTitles=newArray(nImages); 
nTitles=0; 
for (i=1; i<=nImages; i++) { 
	selectImage(i); 
	getDimensions(dummy, dummy, channels, sliceCount, dummy);
	if (sliceCount==1) { 
  		allTitles[nTitles]=getTitle(); 
  		nTitles++; 
	} 
}
title="none"; 
allChannels=newArray("Default","Grays","Red","Green","Blue","Magenta","Cyan","Yellow","biop-Azure","biop-Chartreuse", "biop-BrightPink","biop-Amber","biop-SpringGreen", "biop-ElectricIndigo");
scalepositionoptions=newArray("Lower Right","Lower Left","Upper Right","Upper Left");
if (nTitles <1) exit("No non-Stack Window Open"); 
Dialog.createNonBlocking("Select input"); 
Dialog.addChoice("Name", allTitles);  
Dialog.addMessage("Select channels to save...");
Dialog.addCheckbox("Ch1", true);
Dialog.addCheckbox("Ch2", true);
Dialog.addCheckbox("Ch3", true);
Dialog.addCheckbox("Ch4", true);
Dialog.addMessage("Select LUTs for image (optional):");
Dialog.addChoice("Ch1 LUT", allChannels); 
Dialog.addChoice("Ch2 LUT", allChannels); 
Dialog.addChoice("Ch3 LUT", allChannels); 
Dialog.addChoice("Ch4 LUT", allChannels);
Dialog.addMessage("For the README file (optional):");
Dialog.addString("Label for Ch1:", "Ch1");
Dialog.addString("Label for Ch2:", "Ch2");
Dialog.addString("Label for Ch3:", "Ch3");
Dialog.addString("Label for Ch4:", "Ch4");
Dialog.addString("Region:","N/A");
Dialog.addString("Notes:","N/A");
Dialog.addCheckbox("Close all after finishing?", false);
Dialog.addCheckbox("Scale bar?", false);
Dialog.addCheckbox("Generate Pop-out?", false);
Dialog.addChoice("Scale Position", scalepositionoptions);
Dialog.show(); 
window=Dialog.getChoice();
Ch1Save=""+ Dialog.getCheckbox(); // <""> is necessary before adding the number so it is a string. 
Ch2Save=""+ Dialog.getCheckbox();
Ch3Save=""+ Dialog.getCheckbox();
Ch4Save=""+ Dialog.getCheckbox();
C1LUT=Dialog.getChoice();
C2LUT=Dialog.getChoice();
C3LUT=Dialog.getChoice();
C4LUT=Dialog.getChoice();
LUTlist=newArray(C1LUT, C2LUT, C3LUT, C4LUT);
C1name=Dialog.getString();
C2name=Dialog.getString();
C3name=Dialog.getString();
C4name=Dialog.getString();
region=Dialog.getString();
notes=Dialog.getString();
labellist=newArray(C1name,C2name,C3name,C4name);
Close = Dialog.getCheckbox();
Scale = Dialog.getCheckbox();
popout = Dialog.getCheckbox();
position = Dialog.getChoice();
// Get some information about the selected image
getDimensions(dummy, dummy, channels, sliceCount, dummy); //extract the number of channels
selectWindow(window); 
name=getTitle();
saveName=getTitleStripExt();
File.makeDirectory(dirSave + saveName+"/"); 
dirSave=dirSave + saveName+"/";
channellist=newArray(Ch1Save,Ch2Save,Ch3Save,Ch4Save); //it's fine if the channel list exceeds the # of channels in the image. Stack.setActiveChannels will ignore the string contents beyond the # of channels.
//comboList= getCombos(channellist);

//1.5 Initialize Log File
print("*******************************************************************************************************************************************");
print("Figures generated on: "+date);
print("Script: 20200717_FigureGenerator v1.3");
print("Image: "+name);
print("Region: "+region);
print("Ch 1: "+C1LUT+" "+C1name);
print("Ch 2: "+C2LUT+" "+C2name);
print("Ch 3: "+C3LUT+" "+C3name);
print("Ch 4: "+C4LUT+" "+C4name);
print("Notes: "+notes);
print("*******************************************************************************************************************************************");

//***********************************************	
//Step 2. Save original tiff with correct LUTs
//***********************************************
selectWindow(name);
for (i=0; i<LUTlist.length; i++){
	if(LUTlist[i]!="Default"){
		Stack.setChannel(i+1);
		run(LUTlist[i]);
	}
}
saveAs(saveType, dirSave+saveName);
name=getTitle();
//***********************************************	
//Step 2.5 Save Brightness/contrast settings to log
//***********************************************
print("Channel Min, Max Display Settings");
for (i = 0; i < channellist.length; i++) {
	if (channellist[i]=="1"){
		Stack.setChannel(i);
		getMinAndMax(min, max);
		print("Ch "+i+1+"- Min: "+min+"   Max: "+max);
	}
}

//***********************************************	
//Step 3. Save channel combinations
//***********************************************
saveChannelCombo(name, saveName, channellist,labellist);
//***********************************************	
//Step 4. Optional popout...
//***********************************************
//4.1 User input to get the area to be popped out
if (popout){
	selectWindow(name);
	w=getWidth();
	lineThick=round((w/200)+1); //guesstimate the right width for the cutout
	run("Overlay Options...", "stroke=white width="+lineThick+" fill=none set");
	for (i = 0; i < 100; i++) { //add up to 100 popouts from an image
		dup="crop_"+i; 
		run("Select None");
		waitForUser("Select region to be cropped from original image");
		run("Duplicate...", "title="+dup+" duplicate");
		//4.2 Save channel combinations of cropped region
		saveChannelCombo(dup,saveName+dup,channellist,labellist);
		wait(300);
		//4.3 Save original image with cropped region overlay
		selectWindow(name);
		selectWindow(name);
		run("Add Selection...");
		Dialog.createNonBlocking("Additional pop-outs?");
		Dialog.addCheckbox("Check box to make another pop-out",false);
		Dialog.show();
		another=Dialog.getCheckbox();
		if (!another){
			i=100;
		}
}
selectWindow(name);
if (Scale){
	scalesize=setScaleSize();
	scaleBar(position,scalesize);
}
run("Flatten");
saveAs(saveType, dirSave+saveName+"_overview");
}
//***********************************************	
//Step 5. Save log file for metadata.
//***********************************************
	selectWindow("Log");
	saveAs("Text",dirSave+date+"_FigureMetadata_"+saveName+".txt");
	closeIfOpen("crop_1");
	closeIfOpen("crop_0");
	closeIfOpen("crop_2");

if (Close==true){
	run("Close All");
}

function getTitleStripExt() { 
  t = getTitle(); 
  t = replace(t, ".tif", "");         
  t = replace(t, ".tiff", "");       
  t = replace(t, ".lif", "");       
  t = replace(t, ".lsm", "");     
  t = replace(t, ".czi", "");       
  t = replace(t, ".nd2", "");     
  return t; 
}
function getCombos(channellist){
	channelCombos=newArray(channellist[0]+channellist[1]+channellist[2]+channellist[3]); //adds original 4 channel combo to list of combos
	optionsList=newArray("1000","0100","0010","0001");
	for (i = 0; i < channellist.length; i++) {
		if(channellist[i]=="1"){
			channelCombos=Array.concat(channelCombos,optionsList[i]);
		}
	}
	return channelCombos;
}
function setScaleSize(){
	w=getWidth();
	getPixelSize(unit, pw, ph, pd);
	width=w*pw; //width in calibrated units
	if (width<50){
		scalesize=10;
	}
	if (width>50 && width<125){
		scalesize=20;
	}
	if (width>125 && width<225){
		scalesize=50;
	}
	if (width>225 && width<525){
		scalesize=100;
	}
	if (width>525 && width<1100){
		scalesize=200;
	}
	if (width>1100 && width<5000){
		scalesize=500;
	}
	if (width>5000 && width<20000){
		scalesize=2000;
	}
	if (width>20000 && width<30000){
		scalesize=5000;
	}
	return scalesize;
}
function saveChannelCombo(name,saveName,channellist,labellist){
	//channellist must be a list of strings for each channel of the image (e.g., '1','0','1','1')
	//labellist should be a corresponding string to describe this combo (e.g., 'gfp')
	for (i=0; i<channellist.length; i++){
		all=channellist[0]+channellist[1]+channellist[2]+channellist[3];
		selectWindow(name);
		Stack.setActiveChannels(all);
		run("Duplicate...", "title=RGB duplicate");
		run("RGB Color");
		if (Scale){
			scalesize=setScaleSize();
			scaleBar(position,scalesize);
		}
		saveAs(saveType, dirSave+saveName+"_merge");
		Stack.getUnits(X, Y, Z, Time, Value);
		if (Scale){
			print("Scale bar size for "+getTitle()+" "+"is "+scalesize+" "+X+"s");
		}
		run("Close");
		closeIfOpen("RGB");
		for (i = 0; i < channellist.length; i++) {
			if(channellist[i]=="1"){
				selectWindow(name);
				Stack.setChannel(i+1);
				run("Duplicate...", "title=2");
				run("Grays");
				run("RGB Color");
				if (Scale){
					scalesize=setScaleSize();
					scaleBar(position,scalesize);
				}
				saveAs(saveType, dirSave+saveName+"_"+labellist[i]);
				run("Close");
			}
		}
		//run("Close");
	}
}

function closeIfOpen(string) {
		/*
		 * This function is useful if you desire to close a window by name but there is a chance depending on user action
		 * that the window may already be closed. 
		 */
	 	if (isOpen(string)) {
	         selectWindow(string);
	         run("Close");
	    }
	}
function scaleBar(position, scalesize){
	w=getWidth();
	height=round(scalesize/5);
	run("Scale Bar...", "width="+scalesize+" height="+height+" font=1 color=White background=None location=["+position+"] hide label");
}
function getDate(){
		//This function gets and returns a string of the current date in yearmonthday format.
		getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
		if (dayOfMonth<10) {dayOfMonth = "0"+dayOfMonth;}
		month=month+1;
		if (month<10) {month = "0"+month;}
		return toString(year)+toString(month)+toString(dayOfMonth);
	}