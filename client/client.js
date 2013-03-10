
function ChunkOfWords(_cid, _string, _x, _y)
{
	this.cid = _cid;
	this.string = _string;
	this.x = _x;
	this.y = _y;
}

var socket;
console.log("sketch id: " + getProcessingSketchId());
var pjs;
var myCid;
//var words;


function initClient()
{
	pjs = Processing.getInstanceById(getProcessingSketchId());
 	socket = io.connect('ws://192.168.1.239:80');

 	//words = new pjs.ArrayList();
	//words.add(new pjs.ChunkOfWords(new pjs.PVector(0,0), "h", -1));

 	socket.on('init', function(data) {
 		mySid = data.cid;
		console.log("client ID: " + mySid);
		pjs.initSelf(mySid, data.type, data.x, data.y, data.size, data.arms, data.r, data.g, data.b);
		pjs.setJavaScript(parent);
	});

	document.onkeydown = function(e)
{
	if (e.keyCode == 8)
	{
		pjs.deleteKey();
		return false;
	}
}


	socket.on('key_press', function (data) {
  		pjs.serverKeyPressed(data.cid, data.key);
	});

	socket.on('key_release', function (data) {
  		pjs.serverKeyReleased(data.cid, data.key);
	});

	socket.on('new_creature', function (data) {
		pjs.serverAddNewCreature(data.cid, data.type, data.x, data.y, data.size, data.arms, data.r, data.g, data.b);
	});

	socket.on('del_creature', function (data) {
		console.log("got remove creature " + data.cid);
		pjs.serverRemoveCreature(data.cid);
	});

	socket.on('update_pos', function (data) {
		pjs.serverUpdateCreaturePos(data.cid, data.x, data.y, data.rotation);
	});

	socket.on('next_frame', function (data) {
		pjs.serverNextFrame();
	});

	socket.on('take_word', function(data) {
		console.log("got take_word");
		var chunkList = new pjs.ArrayList();
		chunkList.add(new pjs.ChunkOfWords(new pjs.PVector(data.chunk.x, data.chunk.y), data.chunk.string, -1));
		pjs.serverTakeData(chunkList);
	});

	socket.on('take_words', function (data) {
		console.log("got take_words");
		var chunkList = new pjs.ArrayList();
		for (var i=0; i<data.chunks.length; i++)
		{
			chunkList.add(new pjs.ChunkOfWords(new pjs.PVector(data.chunks[i].x, data.chunks[i].y), data.chunks[i].string, -1));
		}

		pjs.serverTakeData(chunkList);
	});

	setInterval(function() {
		pjs.serverGimmeYourPosition();
	}, 2000);
}

function gimmeAllTheWords()
{
	socket.emit('get_all_words', 
	{
		'cid':mySid
	});

	//console.log("sending data: " + words);
	//pjs.serverTakeData(words);
};

function keyPress(cid, key)
{
	//console.log("key pressed["+cid+"]: " + key);
	socket.emit('key_press', {'cid':cid, 'key' : key });
}

function keyRelease(cid, key)
{
	//console.log("key released["+cid+"]: " + key);
	socket.emit('key_release', {'cid':cid, 'key' : key} );
}

function updateSelfPosition(cid, x, y, rotation)
{
	socket.emit('set_position', {'cid':cid, 'x':x, 'y':y, 'rotation':rotation});
};

function addNewCreature(cid, type, x, y, size, arms, r, g, b)
{
	socket.emit('new_creature',
		{
			'cid':cid,
			'type':type,
			'x':x,
			'y':y,
			'size':size,
			'arms':arms,
			'r':r,
			'g':g,
			'b':b
		});
};

function takeChunkOfWords(chunk)
{
	socket.emit('new_word', {'chunk' : new ChunkOfWords(myCid, chunk.str, chunk.pos.x, chunk.pos.y)});
}

window.onload = function() {
	setTimeout(initClient, 2000);
};


//$(function(){
    /*
     * this swallows backspace keys on any non-input element.
     * stops backspace -> back
     */
    // var rx = /INPUT|SELECT|TEXTAREA/i;

    // document.bind("keydown keypress", function(e){
    //     if( e.which == 8 ){ // 8 == backspace
    //         if(!rx.test(e.target.tagName) || e.target.disabled || e.target.readOnly ){
    //             e.preventDefault();
    //         }
    //     }
    // });
//});



