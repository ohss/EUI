var dataArray = [58,58,58,58]; 
var Adata = [[],[],[]];

var serialport = require("serialport");

var SerialPort = serialport.SerialPort; // localize object constructor


var sp = new SerialPort("/dev/tty.usbserial-A90RR5T1", {
  parser: serialport.parsers.readline("\n"),
  baudrate : 9600 
});


sp.on('open', function(){
  console.log('Serial Port Opend');
  sp.on('data', function(data){
    //console.log('data received: ' + data);

    if (data.trim() !== '') {
      line = data;
      console.log(line)
      array = data.split("	");
      dataArray.shift();
      dataArray.push(parseFloat(array[2]));

      for(i = 0 ; i < 3 ;i++){
      	if(Adata[i].length <= 3)
      		Adata[i].push(parseFloat(array[3+i]));
      	else{
      		Adata[i].shift();
      		Adata[i].push(parseFloat(array[3+i]));
      	}
      }
  	}

  	//z average
  	average= 0;
  	for(i in dataArray){
  		average += dataArray[i];
  	}

  	average = average/dataArray.length;


  	if(	array[3]>1.5 ||
  		array[4]>1.5 ||
  		array[5]>1.5){
  		console.log('I shake with acc data------------------------------------------');
  	}

  	//console.log("average is " + average+ " array length is "+dataArray.length);
  	//console.log(array[2] / average);

  	if(Math.abs(array[2] / average <0.8 )|| Math.abs(array[2] / average >1.2 )){
  		console.log("it shake!!!!!!!!!!!!!!!!!");
  	}
  });
});
