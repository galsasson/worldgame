/* @pjs font1=sketch/Osaka-18.vlw,sketch/Osaka-16.vlw */
 
 reature myCreature = null;
HashMap creatures;

int selfID = -1;

final float LIQUID_DRAG = 0.5;

final int TYPE_SINEFISH = 0;
final int TYPE_FASTFISH = 1;
final int TYPE_AIRFIGHTER = 2;

World world;
Clouds clouds;
Bubbles bubbles;
WordSpace wordSpace;
Chat chat;

PImage texture;

void setup()
{
  size(900, 400);
  colorMode(HSB, 360, 100, 100, 100);
  smooth();
  frameRate(40);
  
  world = new World();
  clouds = new Clouds(3000, 2000);
  bubbles = new Bubbles(3000, 1000);

  chat = new ChatWindow();
  wordSpace = new WordSpace(loadFont("sketch/Osaka-16.vlw", 16));
  
  creatures = new HashMap();
  
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
  
  background(0);

  pushMatrix();
  
  translate(-myCreature.getPosition().x+width/2, -myCreature.getPosition().y+height/2);

  world.draw();
  clouds.draw();
  bubbles.draw();

  wordSpace.display(myCreature.getPosition(), 500);
  
  Iterator i = creatures.entrySet().iterator();
  while(i.hasNext())
  {
    Creature c = (Creature)i.next().getValue();
    //console.log("fish = " + i.next().getKey());

    c.applyDrag(LIQUID_DRAG);
    
    c.update();
    c.display();
  }

  chat.update();
  chat.display(myCreature.getPosition().x-width/2, myCreature.getPosition().y+height/2);

  popMatrix();  
}

void sendText()
{
  String str = new String(chat.getString());
  chat.emptyString();

  javascript.takeChunkOfWords(new ChunkOfWords(myCreature.getPosition().get(), str, -1));
  
  //wordSpace.addWord(new ChunkOfWords(myCreature.getPosition().get(), str, -1));
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

class SineFish implements Creature
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
    setAllArmsSpeed(0.02);


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
  
  public void display()
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

  public void setPosition(PVector p)
  {
    pos = p;
  }

  public PVector getPosition()
  {
    return pos;
  }

  public PVector getVelocity()
  {
    return vel;
  }

  public void setVelocity(PVector v)
  {
    vel = v;
  }

  public void setRotation(float r)
  {
    ang = r;
  }

  public float getRotation()
  {
    return ang;
  }

  public void setUp(boolean is) { moveUp = is; }
  public boolean getUp() { return moveUp; }
  public void setRight(boolean is) { moveRight = is; }
  public boolean getRight() { return moveRight; }
  public void setDown(boolean is) { moveDown = is; }
  public boolean getDown() { return moveDown; }
  public void setLeft(boolean is) { moveLeft = is; }
  public boolean getLeft() { return moveLeft; }

}

/****************************************************************************/
/****************************************************************************/
/****************************************************************************/


class FastFish implements Creature
{
  PVector pos;
  PVector vel;
  PVector acc;
  
  float angAcc;
  float angVel;
  float ang;
  
  float size;
  float mass;
  
  float t;
  float flapSpeed;
  
  ArrayList<FastBubble> bubbles;

  color col;

  boolean moveUp = false;
  boolean moveDown = false;
  boolean moveRight = false;
  boolean moveLeft = false;
  
  public FastFish(PVector pos, float initSize, color c)
  {
    this.pos = pos;
    this.vel = new PVector(0, 0);
    this.acc = new PVector(0, 0);
    
    col = c;

    size = initSize;
    mass = size*2;
    
    ang = 0;
    angVel = 0;
    angAcc = 0;
    
    bubbles = new ArrayList<FastBubble>();
    
    flapSpeed = 0.1;
    t=0;
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
    {
      flapSpeed = 0.8;
      PVector angVec = new PVector(cos(ang-PI/2), sin(ang-PI/2));
      applyForce(PVector.mult(angVec, 4));
    }
    else 
    {
      flapSpeed = 0.1;
    }

    if (moveLeft)
    {
      PVector s = new PVector(17, -22);
      float sxTemp = s.x;
      s.x = s.x*cos(ang) - s.y*sin(ang);
      s.y = sxTemp*sin(ang) + s.y*cos(ang);
      PVector angVec = new PVector(cos(ang), sin(ang));
      PVector initSpeed = PVector.mult(angVec, random(2,4));
      angAcc = -PI/200;
      bubbles.add(new FastBubble(PVector.add(pos, s), initSpeed, random(2, 8)));
    }

    if (moveRight)
    {
      PVector s = new PVector(-17, -22);
      float sxTemp = s.x;
      s.x = s.x*cos(ang) - s.y*sin(ang);
      s.y = sxTemp*sin(ang) + s.y*cos(ang);
      PVector angVec = new PVector(cos(ang+PI), sin(ang+PI));
      PVector initSpeed = PVector.mult(angVec, random(2,4));
      angAcc = PI/200;
      bubbles.add(new FastBubble(PVector.add(pos, s), initSpeed, random(2, 8)));
    }

    vel.add(acc);
    pos.add(vel);
    
    acc.mult(0);
    t+=flapSpeed;
    
    angVel += angAcc;
    ang += angVel;
    if (ang > PI*2)
          ang -= PI*2;
    angAcc = 0;
    
    // like friction for angular motion
    angVel *= 0.9;
    
    for (int i=bubbles.size()-1; i>=0; i--)
    {
      FastBubble b = (FastBubble)bubbles.get(i);
      if (!b.isAlive())
      {
        bubbles.remove(i);
        continue;
      }
      
      b.applyForce(new PVector(0, -0.03));
      b.update();
    }
  }
  
  public void display()
  {
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(ang);
    
    
    // draw head
    float yOffset = -23;

    fill(col);//50, 100, 100, 100);
    noStroke();
    ellipse(-10, yOffset, 5, 5);
    ellipse(10, yOffset, 5, 5);

    fill(0, 0, 100, 20);
    stroke(0, 0, 100, 20);
    beginShape();
    curveVertex(5, yOffset-4);
    curveVertex(15, yOffset-8);
    curveVertex(15, yOffset+8);
    curveVertex(5, yOffset+4);
    curveVertex(-5, yOffset+4);
    curveVertex(-15, yOffset+8);
    curveVertex(-15, yOffset-8);
    curveVertex(-5, yOffset-4);
    curveVertex(5, yOffset-4);
    curveVertex(15, yOffset-8);
    curveVertex(15, yOffset+8);
    endShape();
    
    yOffset = -10;
    float x=0, y=0;
    for (int i=0; i<9; i++)
    {
      x = sin(t-i)*i;
      y = yOffset;
      ellipse(x, y, 15-i*2, (10-i));
      ellipse(x, y, 3, 3);
      yOffset += (12-i);
    }
    
    popMatrix();
    
    for (int i=0; i<bubbles.size(); i++)
    {
      ((FastBubble)bubbles.get(i)).draw();
    }

  }
  
  public PVector getPosition()
  {
    return pos;
  }

  public void setPosition(PVector p)
  {
    pos = p;
  }

  public PVector getVelocity()
  {
    return vel;
  }

  public void setVelocity(PVector v)
  {
    vel = v;
  }

  public void setRotation(float r)
  {
    ang = r;
  }

  public float getRotation()
  {
    return ang;
  }

  public void setUp(boolean is) { moveUp = is; }
  public boolean getUp() { return moveUp; }
  public void setRight(boolean is) { moveRight = is; }
  public boolean getRight() { return moveRight; }
  public void setDown(boolean is) { moveDown = is; }
  public boolean getDown() { return moveDown; }
  public void setLeft(boolean is) { moveLeft = is; }
  public boolean getLeft() { return moveLeft; }

}

/****************************************************************************/
/****************************************************************************/
/****************************************************************************/



class FastBubble
{
  PVector pos;
  PVector vel;
  PVector acc;
  
  float size;
  
  float t;
  
  public FastBubble(PVector pos, PVector vel, float size)
  {
    this.pos = pos;
    this.vel = vel;
    this.size = size;
    
    // simulate drag for x axis
    vel.x *= 0.8;
    
    this.acc = new PVector(0, 0);
    t = 0;
  }
  
  public void update()
  {
    pos.add(vel);
    vel.add(acc);
    
    t+=0.5;
    
    acc.mult(0);
  }
  
  public void applyForce(PVector force)
  {
    PVector f = PVector.mult(force, size);
    acc.add(f);
  }
  
  public boolean isAlive()
  {
    if (pos.y < 1900)
          return false;
          
    return true;
  }
  
  public void draw()
  {
    pushMatrix();
    translate(pos.x, pos.y);
    
    fill(0, 0, 100, 60);
    stroke(0, 0, 100, 80);
    strokeWeight(1);
    
    ellipse(0+sin(t)*2, 0, size, size);
    
    popMatrix();
  }
}

/****************************************************************************/
/****************************************************************************/
/****************************************************************************/

class ChatWindow
{
  String currentText;
  PFont font;
  
  float tw;
  int cursorCounter = 0;
  
  public ChatWindow()
  {
    currentText = "";
    font = loadFont("sketch/Osaka-18.vlw");
    textFont(font, 18);
    cursorCounter = 0;
    tw = 0;
  }
  
  public void handleChar(char c)
  {
    if ((c >= 32 && key <= 126))
      addString(String.fromCharCode(c));
  }

  public String getString()
  {
    return currentText;
  }
  
  public void emptyString()
  {
    currentText = "";
    tw = textWidth(currentText);
  }
  
  public void addString(String s)
  {
    if (currentText.length >= 80) 
      return;

    currentText = currentText + s;
    tw = textWidth(currentText);
  }
  
  public void deleteChar()
  {
    if (currentText.length() > 0)
      currentText = currentText.substring(0, currentText.length()-1);
    tw = textWidth(currentText);
  }
  
  public void update()
  {
    cursorCounter++;
    
    if (cursorCounter > 60)
      cursorCounter = 0;
  }
  
  public void display(float x, float y)
  {
    
    pushMatrix();
    translate(x, y);
    
    textFont(font, 18);
    strokeWeight(2);
    stroke(0, 0, 100, 80);
    fill(0, 0, 100, 20);
    
    rect(0, -25, width, 23, 5, 5, 5, 5);
    fill(250);
    text(currentText, 5, -7);
    
    /* draw cursor */
    if (cursorCounter < 30)
      line (tw+7, -20, tw+7, -6);
      
    popMatrix();
  }
}

/****************************************************************************/
/****************************************************************************/
/****************************************************************************/

class ChunkOfWords
{
  PVector pos;  
  String str;
  int life;
  
  public ChunkOfWords(PVector p, String s, int l)
  {
    pos = p;
    str = s;
    life = l;
  }
  
  public void display()
  {
    if (life==0)
      return;
    
    if (life > 0) life--;
    
    fill(0, 0, 50, 50);
    
    pushMatrix();
    translate(pos.x, pos.y);
    text(str, 0, 0);
    popMatrix();
  }
}

/****************************************************************************/
/****************************************************************************/
/****************************************************************************/


class WordSpace
{
  ArrayList<ChunkOfWords> words;
  PFont font;
 
  public WordSpace(PFont f)
  {
    font = f;
    words = new ArrayList<ChunkOfWords>();
  }
  
  public void addWord(ChunkOfWords word)
  {
    words.add(word);
    javascript.takeChunkOfWords(word);
  }
  
  public void display(PVector p, float radius)
  {
    textFont(font, 16);

    for (int i=0; i<words.size(); i++)
    {
      ChunkOfWords chunk = (ChunkOfWords)words.get(i);
      if (chunk.pos.dist(p) < radius)
        words.get(i).display();
    }
  }

  public void askForData()
  {
    javascript.gimmeAllTheWords();
  }

  public void take(ArrayList<ChunkOfWords> chunks)
  {
    words.addAll(chunks);
  }
}

/****************************************************************************/
/****************************************************************************/
/****************************************************************************/

// When AirFlyer goes into water, she loses control to the sea creature.

class AirFighter implements Creature {

  int wFly = 8;           //width of Center body
  int hFly = 22;          //height of Center body
  float wings;       //Amount of wings
  float rotation = 0.06; //how big is the flap
  float c = 205;          //color gray scale  
  float mass;             //weight of fighter
  float flapW;             //wing flapW
  int flapDir;            //wing direction
  float flapAmount;       //flap counter

  boolean moveUp = false;
  boolean moveLeft = false;
  boolean moveDown = false;
  boolean moveRight = false;

  PVector location;
  PVector wing;
  PVector velocity;
  PVector acceleration;

  float direction = 0;

  AirFighter(float w, float m, float x, float y) {
    wings = w;
    mass = m;
    location = new PVector(x, y);
    wing = new PVector(0, 0);
    velocity = new PVector(0, 0);
    acceleration = new PVector(0, 0);
    flapW=0;
    flapDir=1;
    flapAmount=0.004;
  }

  void applyDrag(float c) {
  }

  public void update() { 
    flap();
    assolacion();

    velocity.add(acceleration);
    location.add(velocity);
    velocity.mult(0.95);
    acceleration.mult(0);

    if (moveUp) {goStrait();}
    if (moveLeft) {rotateLeft();}
    if (moveDown) {goStrait();}
    if (moveRight){rotateRight();}
  }

  public void display() {
    //Body Air Fighter
    strokeWeight(1);
    stroke(0,70);
    fill(0);

    pushMatrix();
    translate(location.x, location.y);
    //rotate(heading);
    rotate(radians(direction));

    //body
    ellipse(0, 0, wFly+wings/8, hFly+wings/10);
    ellipse(0, 8, wFly-6+wings/8, hFly+wings/10);  

    //Right Wing AirFighter
    pushMatrix();
    translate(wing.x, wing.y);
    rotate(rotation+flapW);
    for (float i=wings; i>0; i--) {
      fill(c-i*25,50+i*2);
      rotate(rotation+flapW);
      bezier(32, 0, -45+i*5, 0, 30-i*2, -i*4, 30+i*6, -i*5);
      fill(255, 0, 0);
    }
    popMatrix();

    //Left Wing AirFighter
    pushMatrix();
    translate(wing.x, wing.y);
    rotate(-rotation-flapW);
    for (float i=wings; i>0; i--) {
      fill(c-i*25,50+i*2);
      rotate(-rotation-flapW);
      bezier(-32, 0, 45-i*5, 0, -30+i*2, -i*4, -30-i*6, -i*5);
    }
    popMatrix();
    popMatrix();
  }

  public PVector getPosition() {
    return location;
  }

  public void setPosition(PVector p)
  {
    location = p;
  }

  public float getRotation()
  {
    return radians(direction);
  }
  
  public void setRotation(float r)
  {
    direction = degrees(r);
  }

  void applyForce(PVector force) {
    PVector f = PVector.div(force, mass);
    acceleration.add(f);
  }

  void assolacion() {
    PVector move = new PVector(0, 0.002*sin(radians(frameCount*5))); //location+raduis*sin(radians(angle))
    applyForce(move);
  }

  void flap() {
    if (flapDir==1 && flapW>0.05) {
      flapDir=-1;
    } 
    if (flapDir==-1 && flapW < -0.05) {
      flapDir=1;
    }
    if (flapDir<0) {
      flapW += flapAmount*0.6*flapDir;
    } 
    else {
      flapW += flapAmount*flapDir;
    }
  }

  void rotateLeft() {
    direction--;
    PVector force = new PVector(cos(radians(direction)-PI/2), sin(radians(direction)-PI/2));// PVector.fromAngle(radians(direction)-PI/2);
    applyForce(force);
  }
  void rotateRight() {
    direction++;
    PVector force = new PVector(cos(radians(direction)-PI/2), sin(radians(direction)-PI/2));//PVector.fromAngle(radians(direction)-PI/2);
    applyForce(force);
  }
  void goStrait() {
    PVector force = new PVector(cos(radians(direction)-PI/2), sin(radians(direction)-PI/2));//PVector.fromAngle(radians(direction)-PI/2);
    applyForce(force);
    applyForce(force);
  }

  void underwater() {
    // give control to sea creature
  }

  public PVector getVelocity()
  {
    return velocity;
  }

  public void setVelocity(PVector vel)
  {
    velocity = vel;
  }

  public void setUp(boolean is) { moveUp = is; }
  public boolean getUp() { return moveUp; }
  public void setRight(boolean is) { moveRight = is; }
  public boolean getRight() { return moveRight; }
  public void setDown(boolean is) { moveDown = is; }
  public boolean getDown() { return moveDown; }
  public void setLeft(boolean is) { moveLeft = is; }
  public boolean getLeft() { return moveLeft; }
}


/****************************************************************************/
/****************************************************************************/
/****************************************************************************/

class Bubble {
  PVector location;
  PVector velocity;
  PVector acceleration;
  PImage img;
  int w=2950; //weidth
  int h=1900; //hight
  
  float scl;
  
  Bubble(int num) {
    location = new PVector(random(w), random(h,h+950));
    velocity = new PVector(0,0);
    acceleration = new PVector();
    img = loadImage("sketch/data/bubble"+num+".png");
    
    scl = random(0.1,0.8);
  }

  void applyForce(PVector force) {
    acceleration.add(force);
  }
  void move() {
    
    applyForce(new PVector(random(-0.02,0.02),0));
    applyForce(new PVector(0,-0.03));
    
    
    
    velocity.add(acceleration);
    location.add(velocity);
    acceleration.mult(0);
    velocity.mult(0.99);
  }

  void checkEdges() {
    if ((location.x>w) || (location.x<35)) {
      velocity.x *= -1;
    } 

    if (location.y<h-45) {
    location.y=h+1100;
    }
  }

  void draw() {
    pushMatrix();
    translate(location.x,location.y);
    imageMode(CENTER);
    scale(scl);
    image(img,0,0 );
    popMatrix();
  }
}

/****************************************************************************/
/****************************************************************************/
/****************************************************************************/

class Cloud {
  PVector location;
  PVector velocity;
  PImage img;
  int w=3000; //weidth
  int h=1650; //hight

  Cloud(int num) {
    location = new PVector(random(w), random(h));
    velocity = new PVector(random(0.05,0.5),0);
    img = loadImage("sketch/data/cloud"+num+".png");
  }

  void move() {
    location.add(velocity);
  }

  void checkEdges() {
    if ((location.x>=w) || (location.x<0)) {
      velocity.x *= -1;
    } 
  }

  void draw() {
    image(img, location.x, location.y);
  }
}

/****************************************************************************/
/****************************************************************************/
/****************************************************************************/

class Bubbles {
  ArrayList<Bubble> bubbles; //location

  Bubbles(float x, float y) {
    bubbles = new ArrayList();


    for (int i=0; i<100; i++) {
      bubbles.add(new Bubble(int(random(1, 5))));
    }
  }

  void draw() {
    for (int i=0; i<bubbles.size(); i++) {
      bubbles.get(i).draw();     
      bubbles.get(i).move();     
      bubbles.get(i).checkEdges();     
    }
  }
}

/****************************************************************************/
/****************************************************************************/
/****************************************************************************/

class Clouds {
  ArrayList<Cloud> clouds; //location

  Clouds(float x, float y) {
    clouds = new ArrayList();


    for (int i=0; i<30; i++) {
      clouds.add(new Cloud(int(random(1, 4))));
    }
  }

  void draw() {
    for (int i=0; i<clouds.size(); i++) {
      clouds.get(i).draw();     
      clouds.get(i).move();     
      clouds.get(i).checkEdges();     
    }
  }
}

/****************************************************************************/
/****************************************************************************/
/****************************************************************************/

// take Gal's world and put it here. Add your fighter to his world.
class World {
  //sun
  int  sunR = 450;
  int colorY= 62;
  color colorE=0;
  float sizeSunR=50;
  boolean sizeSun=false;

  int w=3000; //wiedth ocean
  int h=2000; //hight ocean
  float yoff = 0.0; //ocean movment
  // Ocean
  ArrayList<PVector> points;

  public World() {
    //Dots in ocean
    points = new ArrayList();
    for (int i=0; i<500; i++)
    {
      points.add(new PVector(random(w), random(h-200, w)));
    }
  }

  public void draw() {
    noStroke();
    //Air World
    fill(213, 24, 99);
    rect(0, 0, w, h);
    //Sea World
    //background
    fill(213, 83, 32);
    rect(0, h, w, h-1000);

    //ocean moving
    fill(213, 83, 32);
    beginShape(); 
    float xoff = 0;
    for (float x = 0; x <=w; x += 10) {
      float offset = map(noise(xoff, yoff), 0, 1, -25, 60);
      vertex(x, h-150+offset); 
      xoff += 0.01;
    }
    yoff += 0.01;
    vertex(w, h+150);
    vertex(0, h+150);
    endShape(CLOSE);

    // Dots
    fill(0, 0, 100, 20);
    for (int i=0; i<points.size(); i++)
    {
      ellipse(points.get(i).x, points.get(i).y, 2, 2);
    }
    
    sunDraw();
  }


  void sunDraw() {
    if (sizeSun) {
      sizeSunR = sizeSunR + .35;
      if (sizeSunR > 100) {
        sizeSun = false;
      }
    } 
    else {
      sizeSunR = sizeSunR - .35;
      if (sizeSunR < 20) {
        sizeSun = true;
      }
    }
    noStroke();
    fill(55, 35, 99, 30); //yellow sun
    ellipse(w-600, h-1400, sunR+sizeSunR, sunR+sizeSunR);
    fill(234, 35, 71, 30); //Greyish sun
    ellipse(600, h-1400, sunR-sizeSunR, sunR-sizeSunR);
    fill(310, 65, 99, 10); // pinkish moon
    ellipse(600, h-1350, sunR/3+sizeSunR, sunR/3+sizeSunR);
  }
}

/****************************************************************************/
/****************************************************************************/
/****************************************************************************/

interface Creature
{
  void applyDrag(float c);
  void update();
  void display();

  void setPosition(PVector pos);
  PVector getPosition();
  void setRotation(float ang);
  float getRotation();

  void setUp(boolean up);
  boolean getUp();
  void setDown(boolean down);
  boolean getDown();
  void setRight(boolean right);
  boolean getRight();
  void setLeft(boolean left);
  boolean getLeft();
}


/****************************************************************************/
/****************************************************************************/
/****************************************************************************/

interface JavaScript
{
  void keyPress(int id, int key);
  void keyRelease(int id, int key);
  void addNewCreature(int id, int type, float x, float y, int size, int arms, int r, int g, int b);
  void updateSelfParams(int id, float xPos, float yPos, float xVel, float yVel, float rot);
  void gimmeAllTheWords();
  void takeChunkOfWords(ChunkOfWords chunk);
}

JavaScript javascript = null;

void setJavaScript(JavaScript js)
{ 
  javascript = js;
  wordSpace.askForData();
 }

void serverNextFrame()
{
  draw();
}

void initSelf(int id, int type, float x, float y, int size, int arms, int h, int s, int b)
{
  selfID = id;

  if (type == TYPE_SINEFISH)
    creatures.put(selfID.toString(), new SineFish(new PVector(x, y), size, arms, color(h, s, b)));
  else if (type == TYPE_FASTFISH)  
    creatures.put(selfID.toString(), new FastFish(new PVector(x, y), size, color(h,s,b)));
  else if (type == TYPE_AIRFIGHTER)
    creatures.put(selfID.toString(), new AirFighter(arms, size, x, y));

  myCreature = (Creature)creatures.get(selfID.toString());
  console.log("myCreature = " + myCreature);

  // call server to add the creature
  javascript.addNewCreature(selfID, type, x, y, size, arms, h, s, b);

  loop();
}

void serverRemoveCreature(int id)
{
  creatures.remove(id);
}

void serverUpdateCreatureParams(int id, float xPos, float yPos, float xVel, float yVel, float r)
{
  Creature c = (Creature)creatures.get(id.toString());
  c.setPosition(new PVector(xPos, yPos));
  c.setVelocity(new PVector(xVel, yVel));
  c.setRotation(r);
}

void serverGimmeYourParams()
{
  Creature c = (Creature)creatures.get(selfID.toString());

  javascript.updateSelfParams(selfID, c.getPosition().x, c.getPosition().y, c.getVelocity().x, c.getVelocity().y, c.getRotation());
}

void serverAddNewCreature(int id, int type, float x, float y, int size, int arms, int h, int s, int b)
{
  console.log("adding new creature with id = ", id);

  if (type == TYPE_SINEFISH)
    creatures.put(id.toString(), new SineFish(new PVector(x, y), size, arms, color(h, s, b)));
  else if (type == TYPE_FASTFISH)  
    creatures.put(id.toString(), new FastFish(new PVector(x, y), size, color(h,s,b)));
  else if (type == TYPE_AIRFIGHTER)
    creatures.put(id.toString(), new AirFighter(arms, size, x, y));

}

void serverKeyPressed(int id, int k)
{
  console.log("got keyPressed from " + id);
  Creature c = (Creature)creatures.get(id.toString());
  console.log("creature = " + c);

  if (k == UP)
    c.setUp(true);
  if (k == RIGHT)
    c.setRight(true);
  if (k == DOWN)
    c.setDown(true);
  if (k == LEFT)
    c.setLeft(true);
}

void serverKeyReleased(int id, int k)
{
  Creature c = (Creature)creatures.get(id.toString());

  if (k == UP)
    c.setUp(false);
  if (k == RIGHT)
    c.setRight(false);
  if (k == DOWN)
    c.setDown(false);
  if (k == LEFT)
    c.setLeft(false);
}

void serverTakeData(ArrayList<ChunkOfWords> words)
{
  wordSpace.take(words);
}

void deleteKey()
{
  chat.deleteChar();
}

void keyPressed()
{
  Creature c = (Creature)creatures.get(selfID.toString());

  if ((keyCode == UP && !c.getUp()) ||
      (keyCode == RIGHT && !c.getRight()) ||
      (keyCode == DOWN && !c.getDown()) ||
      (keyCode == LEFT && !c.getLeft())) {
        if (javascript != null) 
              javascript.keyPress(selfID, keyCode);
      }

  if (keyCode == ENTER)
    sendText();
  else 
    chat.handleChar(key);
}

void keyReleased()
{
  if (keyCode == UP ||
      keyCode == RIGHT ||
      keyCode == DOWN ||
      keyCode == LEFT) 
      {
        if (javascript != null) 
              javascript.keyRelease(selfID, keyCode);
      }
}



