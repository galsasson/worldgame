
var socket;
console.log("sketch id: " + getProcessingSketchId());
var pjs;

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

function updateSelfPosition(cid, x, y)
{
	socket.emit('set_position', {'cid':cid, 'x':x, 'y':y});
}

function addNewCreature(cid, x, y, size, legs)
{
	socket.emit('new_creature', {'cid':cid, 'x':x, 'y':y, 'size':size, 'legs':legs});
}

function initClient()
{
	pjs = Processing.getInstanceById(getProcessingSketchId());
 	socket = io.connect('ws://172.26.12.216:80');

 	socket.on('init', function(data) {
		console.log("client ID: " + data.cid);
		pjs.initSelf(data.cid);
		pjs.setJavaScript(parent);
	});

	socket.on('key_press', function (data) {
  		pjs.serverKeyPressed(data.cid, data.key);
	});

	socket.on('key_release', function (data) {
  		pjs.serverKeyReleased(data.cid, data.key);
	});

	socket.on('new_creature', function (data) {
		pjs.serverAddNewCreature(data.cid, data.x, data.y, data.size, data.legs);
	});

	socket.on('del_creature', function (data) {
		console.log("got remove creature " + data.cid);
		pjs.serverRemoveCreature(data.cid);
	});

	socket.on('update_pos', function (data) {
		pjs.serverUpdateCreaturePos(data.cid, data.x, data.y);
	});

	setInterval(function() {
		pjs.serverGimmeYourPosition();
	}, 2000);
}


window.onload = function() {
	setTimeout(initClient, 2000);
};


