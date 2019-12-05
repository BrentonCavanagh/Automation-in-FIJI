//Input and output directory
//Generate user input
#@File (label="Files to process",description="Location of images you want to process", style="directory") dirIN
#@File (label="Save to",description="Locatoin to save processed images", style="directory") dirOUT
#@String(label="Input file type", description="Filetype of the file you want to process", choices={".lsm",".tif",".nd",".nd2",".zvi"}, value=".lsm") fileType
#@Boolean(label="Autobrighten", description="Will automaticlly brighten all images?") addBright
#@Boolean(label="Add scalebar", description="Adds a scalebar to images") addScale
#@String(label="Preview file format", description="Format for preview file generated. note: PNG is slower!", choices={"tif","png"}, value=".tif") prvType

setBatchMode(true);
count = 0;
listFiles(dirIN);

function listFiles(dirIN) {
     list = getFileList(dirIN);
     print(dirIN, dirOUT);
     for (i=0; i<list.length; i++) {
        current = list[i];
        if (endsWith(list[i], "/")){
           listFiles(""+dirIN+File.separator+list[i]);
        }
        else{
	        ProcessFile(dirIN, dirOUT, fileType, addBright, addScale, prvType, current);
  		}
	}
}

function brighten(channels){
	for (j=0; j<channels; j++) {
		Stack.setChannel(j);
		run("Enhance Contrast", "saturated=0.60");
	}
}

function addScalebar(width, height, pixelWidth, prvType){
	abwidth = width*pixelWidth;
	division = floor(abwidth/4);
	scaleWidth = division;
	if(division > 50){
		rem = division%50;
		scaleWidth = division-rem;
		}
	if(division < 50 && division >10){
		rem = division%5;
		scaleWidth = division-rem;
		}
	scaleHeight = floor(height/40);
	print(scaleHeight, scaleWidth);
	run("Scale Bar...", "width="+scaleWidth+" height="+scaleHeight+" font=10 color=White background=None location=[Lower Right] hide overlay");
	run("Flatten");
	saveAs(prvType, savename+"_"+scaleWidth+"um");
}

function ProcessFile(dirIN, dirOUT, fileType, addBright, addScale, prvType, current){
	filename =  dirIN+File.separator+current; 
	if (endsWith(filename, fileType)){
    	//open(filename);
    	run("Bio-Formats Importer", "open=["+filename+"] color_mode=Default view=Hyperstack");
	 	getDimensions(width, height, channels, slices, frames);
	 	getPixelSize(unit, pixelWidth, pixelHeight);
	 	name = File.nameWithoutExtension;
		savename =  dirOUT+File.separator+name;
		
//1D Image
if (slices==1 && channels==1){
	print("1D image" + filename);
	if (addBright == true){
		run("Enhance Contrast", "saturated=0.35");
		saveAs("tiff", savename);
	}
	else{
		saveAs("tiff", savename);
	}
	if (addScale == true){
		addScalebar(width, height, pixelWidth, prvType);
		}
	
	close();
}
//2D image
if (slices==1 && channels>1){
	print("2D image" + filename);
	run("Make Composite");
	if (addBright == true){
		brighten(channels);
		saveAs("tiff", savename);
	}
	else{
		saveAs("tiff", savename);
	}
	if (addScale == true){
		addScalebar(width, height, pixelWidth, prvType);
		}
	close();
}
//1 channel Zstack
if (slices>1 && channels==1){
	print("1 channel Zstack" + filename);
	run("Z Project...", "start=1 stop"+slices+" projection=[Max Intensity]");
	if (addBright == true){
		run("Enhance Contrast", "saturated=0.35");
		saveAs("tiff", savename);
	}
	else{
		saveAs("tiff", savename);
	}
	if (addScale == true){
		addScalebar(width, height, pixelWidth, prvType);
		}
	
	run("Close All");
}
//3D image
if (slices>1 && channels>1){
	print("3D Image " + filename);
	run("Make Composite");
	run("Z Project...", "start=1 stop"+slices+" projection=[Max Intensity]");
	if (addBright == true){
		getDimensions(width, height, channels, slices, frames);
		brighten(channels);
		saveAs("tiff", savename);
	}
	else{
		saveAs("tiff", savename);
	}
	if (addScale == true){
		addScalebar(width, height, pixelWidth, prvType);
	}
	run("Close All");
}
count++;
		}
	}
//}

//Notify user that script is finished
print("");
print("Finished resaving "+count+" Images");

