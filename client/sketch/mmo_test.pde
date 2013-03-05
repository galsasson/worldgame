//import java.util.Iterator;

Ocean ocean;
SineFish myFish = null;
HashMap fish;

int selfID = -1;

final int FISH_NUM = 3;
final float LIQUID_DRAG = 0.5;

void setup()
{
  size(600, 400);
  colorMode(HSB, 360, 100, 100, 100);
  smooth();
  frameRate(40);
  
  ocean = new Ocean();
  
  fish = new HashMap();
  
  /*
  for (int i=0; i<FISH_NUM; i++)
  {
    float x = random(width*2) - width;
    float y = random(height*2) - height;
    float size = random(2, 16);
    int legs = (int)random(5, 20);
    fish.add(new SineFish(new PVector(x, y), size, legs, color(random(150)+140, 57, 100)));
  }
  */
  
  //myFish = new SineFish(new PVector(0, 0), 5, 10, color(56, 91, 100));
    
  background(0);
  noLoop();
}

void draw()
{
  if (selfID == -1)
  {
    background(0);
    return;
  }
  
  pushMatrix();
  
  translate(-myFish.pos.x+width/2, -myFish.pos.y+height/2);
  ocean.draw();
  
  Iterator i = fish.entrySet().iterator();
  while(i.hasNext())
  {
    SineFish f = (SineFish)i.next().getValue();
    //console.log("fish = " + i.next().getKey());

    f.setAllArmsSpeed(0.02);
    
    f.applyDrag(LIQUID_DRAG);
    
    f.update();
    f.draw();
  }
 
  popMatrix();
  
}

/**************************************************************************/
/**************************************************************************/
/**************************************************************************/

class Ocean
{
  ArrayList<PVector> points;
  
  public Ocean()
  {
    points = new ArrayList();
    
    for (int i=0; i<250; i++)
    {
      points.add(new PVector(random(2000)-1000, random(2000)-1000));
    }
  }
  
  public void draw()
  {
    background(231, 100, 20);
    fill(0, 0, 100, 20);
    
    for (int i=0; i<points.size(); i++)
    {
      ellipse(points.get(i).x, points.get(i).y, 2, 2);
    }
  }
  
}

/**************************************************************************/
/**************************************************************************/
/**************************************************************************/


class SineArm
{
  final int ARM_LENGTH = 15;
  final float WAVE_DENSITY = 0.15;
  
  PVector pos;
  float speed;
  float rot;
  float t;
  
  float length;
  float armWidth;
  
  color tipColor;
  
  public SineArm(float rot, color tipColor)
  {
    this.pos = new PVector();
    this.rot = rot;
    this.tipColor = tipColor;
    
    t = random(0,100);
    speed = 0.02;
    length = ARM_LENGTH + random(4) - 2;
    armWidth=2;
  }
  
  public void setSpeed(float s)
  {
    speed = s;
  }
  
  public void update(float size)
  {
    pos.x = cos(rot)*(size);
    pos.y = sin(rot)*(size);
    armWidth = size/4;
    
    t-=speed;
  }
  
  public void draw()
  {
    pushMatrix();
    stroke(0, 0, 100, 20);
    strokeWeight(armWidth);
    translate(pos.x, pos.y);
    rotate(rot);
    
    for (int i=0; i<length; i+=4)
    {
      line(i, cos(t+i*WAVE_DENSITY)*8*((float)i/length), i+3, cos(t+(i+3)*WAVE_DENSITY)*8*((float)(i+3)/length));
    }
    
    noStroke();
    fill(tipColor);
    ellipse(length+1, cos(t+(length+1)*WAVE_DENSITY)*8*((float)(length+1)/length), 3, 3);
    
    popMatrix();
  }
}

/****************************************************************************/
/****************************************************************************/
/****************************************************************************/

class SineFish
{
  PVector pos;
  PVector vel;
  PVector acc;
  
  float angAcc;
  float angVel;
  float ang;
  
  float initialSize;
  float size;
  float mass;
  
  color tipColor;
  
  float t;

  boolean moveUp = false;
  boolean moveLeft = false;
  boolean moveDown = false;
  boolean moveRight = false;
  
  ArrayList<SineArm> arms;
  
  public SineFish(PVector pos, float initSize, int numOfLegs, color tipColor)
  {
    this.pos = pos;
    this.vel = new PVector(0, 0);
    this.acc = new PVector(0, 0);
    this.moveForce = new PVector(0, 0);
    
    initialSize = initSize;
    size = initialSize;
    mass = size*2;
    
    this.tipColor = tipColor;
    
    ang = 0;
    angVel = 0;
    angAcc = 0;
    
    arms = new ArrayList<SineArm>();
    
    for (float i=0; i<PI*2-0.01; i+=(PI*2)/numOfLegs)
    {
      arms.add(new SineArm(i, tipColor));
    }
    
    t=0;
  }
  
  public void setArmsSpeed(float angle, float speed)
  {
    for (int i=0; i<arms.size(); i++)
    {
      float angleDiff = abs(angle - (ang+arms.get(i).rot));
      if (angleDiff > PI*2)
            angleDiff -= PI*2;
            
      if (angleDiff < PI/3 || angleDiff > 2*PI-(PI/3))
            arms.get(i).setSpeed(speed);
    }
  }
  
  public void setAllArmsSpeed(float speed)
  {
    for (int i=0; i<arms.size(); i++)
    {
      arms.get(i).setSpeed(speed);
    }    
  }
  
  public void applyDrag(float c)
  {
    float speed = vel.mag();
    float dragMag = c * speed * speed;
    
    PVector drag = vel.get();
    drag.mult(-1);
    drag.normalize();
    drag.mult(dragMag);
    applyForce(drag);
  }
  
  public void applyForce(PVector force)
  {
    PVector f = PVector.div(force, mass);
    acc.add(f);
  }
  
  public void update()
  {
    if (moveUp)
      move(new PVector(0, -1));
    if (moveLeft)
      move(new PVector(-1, 0));
    if (moveDown)
      move(new PVector(0, 1));
    if (moveRight)
      move(new PVector(1, 0));

    vel.add(acc);
    pos.add(vel);
    
    acc.mult(0);
    t+=0.01;
    
    angVel += angAcc;
    ang += angVel;
    if (ang > PI*2)
          ang -= PI*2;
    angAcc = 0;
    
    // like friction for angular motion
    angVel *= 0.9;
          
    size = initialSize+noise(t)*3;
    
    for (int i=0; i<arms.size(); i++)
          arms.get(i).update(size);
    
  }
  
  public void draw()
  {
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(ang);
    
    fill(0, 0, 100, 20);
    noStroke();
    ellipse(0, 0, size*2, size*2);
    
    for (int i=0; i<arms.size(); i++)
          arms.get(i).draw();
    
    popMatrix();

  }
  
  void move(PVector d)
  {
    d.normalize();
    applyForce(d);
    d.mult(-1);
    setArmsSpeed(d.heading2D(), 0.3);
    
    if (d.heading2D()>1)
      angAcc = -0.002;
    else
      angAcc = 0.002;    
  }

  public void setUp(boolean is) { moveUp = is; }
  public void setRight(boolean is) { moveRight = is; }
  public void setDown(boolean is) { moveDown = is; }
  public void setLeft(boolean is) { moveLeft = is; }

}

/****************************************************************************/
/****************************************************************************/
/****************************************************************************/

interface JavaScript
{
  void keyPress(int id, int key);
  void keyRelease(int id, int key);
  void addNewCreature(int id, float x, float y, int size, int legs);
  void updateSelfPosition(int id, float x, float y)
}

JavaScript javascript = null;

void setJavaScript(JavaScript js) { javascript = js; }

void initSelf(int id)
{
  selfID = id;
  fish.put(selfID.toString(), new SineFish(new PVector(0, 0), 5, 10, color(56, 91, 100)));
  myFish = (SineFish)fish.get(selfID.toString());
  console.log("myFish = " + myFish);

  // call server to add the creature
  addNewCreature(selfID, 0, 0, 5, 10);

  loop();
}

void serverRemoveCreature(int id)
{
  fish.remove(id);
}

void serverUpdateCreaturePos(int id, float x, float y)
{
  SineFish f = (SineFish)fish.get(id.toString());
  f.pos.x = x;
  f.pos.y = y;
}

void serverGimmeYourPosition()
{
  SineFish f = (SineFish)fish.get(selfID.toString());

  updateSelfPosition(selfID, f.pos.x, f.pos.y);
}

void serverAddNewCreature(int id, float x, float y, int size, int legs)
{
  console.log("adding new creature with id = ", id);
  fish.put(id.toString(), new SineFish(new PVector(x, y), size, legs, color(56, 91, 100)));
}

void serverKeyPressed(int id, int k)
{
  console.log("got keyPressed from " + id);
  SineFish f = (SineFish)fish.get(id.toString());
  console.log("fish = " + f);

  if (k == UP)
    f.setUp(true);
  if (k == RIGHT)
    f.setRight(true);
  if (k == DOWN)
    f.setDown(true);
  if (k == LEFT)
    f.setLeft(true);
}

void serverKeyReleased(int id, int k)
{
  SineFish f = (SineFish)fish.get(id.toString());

  if (k == UP)
    f.setUp(false);
  if (k == RIGHT)
    f.setRight(false);
  if (k == DOWN)
    f.setDown(false);
  if (k == LEFT)
    f.setLeft(false);
}

void keyPressed()
{
  SineFish me = (SineFish)fish.get(selfID.toString());

  if ((keyCode == UP && !me.moveUp) ||
      (keyCode == RIGHT && !me.moveRight) ||
      (keyCode == DOWN && !me.moveDown) ||
      (keyCode == LEFT && !me.moveLeft)) {
        if (javascript != null) 
              javascript.keyPress(selfID, keyCode);
      }
}

void keyReleased()
{
  if (keyCode == UP ||
      keyCode == RIGHT ||
      keyCode == DOWN ||
      keyCode == LEFT) {
        if (javascript != null) 
              javascript.keyRelease(selfID, keyCode);
      }
}



