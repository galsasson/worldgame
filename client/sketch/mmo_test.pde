//import java.util.Iterator;

Ocean ocean;
Creature myCreature = null;
HashMap creatures;

int selfID = -1;

final float LIQUID_DRAG = 0.5;

final int TYPE_SINEFISH = 0;
final int TYPE_FASTFISH = 1;
final int TYPE_AIRFIGHTER = 2;

WordSpace wordSpace;
Chat chat;

void setup()
{
  size(600, 400);
  colorMode(HSB, 360, 100, 100, 100);
  smooth();
  frameRate(30);
  
  ocean = new Ocean();
  chat = new ChatWindow();
  wordSpace = new WordSpace(loadFont("Osaka-16.vlw"));
  
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
  
  pushMatrix();
  
  translate(-myCreature.getPosition().x+width/2, -myCreature.getPosition().y+height/2);
  ocean.draw();

  wordSpace.display(myCreature.getPosition(), 400);
  
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
  
  wordSpace.addWord(new ChunkOfWords(myCreature.getPosition().get(), str, -1));
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
  
  ArrayList<Bubble> bubbles;

  boolean moveUp = false;
  boolean moveDown = false;
  boolean moveRight = false;
  boolean moveLeft = false;
  
  public FastFish(PVector pos, float initSize)
  {
    this.pos = pos;
    this.vel = new PVector(0, 0);
    this.acc = new PVector(0, 0);
    
    size = initSize;
    mass = size*2;
    
    ang = 0;
    angVel = 0;
    angAcc = 0;
    
    bubbles = new ArrayList<Bubble>();
    
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
      bubbles.add(new Bubble(PVector.add(pos, s), initSpeed, random(2, 8)));
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
      bubbles.add(new Bubble(PVector.add(pos, s), initSpeed, random(2, 8)));
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
      Bubble b = (Bubble)bubbles.get(i);
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

    fill(50, 100, 100, 100);
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
      ((Bubble)bubbles.get(i)).draw();
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



class Bubble
{
  PVector pos;
  PVector vel;
  PVector acc;
  
  float size;
  
  float t;
  
  public Bubble(PVector pos, PVector vel, float size)
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
    if (pos.y < -1000)
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
    font = loadFont("Osaka-18.vlw");
    textFont(font, 18);
    cursorCounter = 0;
    tw = 0;
  }
  
  public void handleChar(char c)
  {
    if ((c >= 32 && key <= 126))
      addString(String.fromCharCode(c));
  }

  public void deleteChar()
  {
    deleteChar();
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
    
    fill(0, 0, 100, 50);
    
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
  //  javascript.gimmeAllTheWords();
  }

  public void take(ArrayList<ChunkOfWords> chunks)
  {
    words = chunks;
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
  void updateSelfPosition(int id, float x, float y);
  void gimmeAllTheWords();
  void takeChunkOfWords(ChunkOfWords chunk);
}

JavaScript javascript = null;

void setJavaScript(JavaScript js)
{ 
  javascript = js;
  javascript.gimmeAllTheWords();
 }

void serverNextFrame()
{
  draw();
}

void initSelf(int id, int type, int x, int y, int size, int arms, int r, int g, int b)
{
  selfID = id;

  if (type == TYPE_SINEFISH)
    creatures.put(selfID.toString(), new SineFish(new PVector(x, y), size, arms, color(r, g, b)));
  else if (type == TYPE_FASTFISH)  
    creatures.put(selfID.toString(), new FastFish(new PVector(x, y), size));

  myCreature = (Creature)creatures.get(selfID.toString());
  console.log("myCreature = " + myCreature);

  // call server to add the creature
  addNewCreature(selfID, type, x, y, size, arms, r, g, b);


  //wordSpace.askForData();
  //javascript.gimmeAllTheWords();

  loop();
}

void serverRemoveCreature(int id)
{
  creatures.remove(id);
}

void serverUpdateCreaturePos(int id, float x, float y, float r)
{
  Creature c = (Creature)creatures.get(id.toString());
  c.setPosition(new PVector(x, y));
  c.setRotation(r);
}

void serverGimmeYourPosition()
{
  Creature c = (Creature)creatures.get(selfID.toString());

  updateSelfPosition(selfID, c.getPosition().x, c.getPosition().y, c.getRotation());
}

void serverAddNewCreature(int id, int type, float x, float y, int size, int arms, int r, int g, int b)
{
  console.log("adding new creature with id = ", id);

  if (type == TYPE_SINEFISH)
    creatures.put(id.toString(), new SineFish(new PVector(x, y), size, arms, color(r, g, b)));
  else if (type == TYPE_FASTFISH)  
    creatures.put(id.toString(), new FastFish(new PVector(x, y), size));
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

  if (keyCode == DOWN)
  {
    chat.deleteChar(8);
  }
  else if (keyCode == ENTER)
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



