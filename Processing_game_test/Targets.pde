class Targets {
  int[] notes;
  int aftertouch;
  int[] orientation;
  int bend;

  Targets(int[] notes, int aftertouch, int[] orientation, int bend) {
    this.notes = notes;
    this.aftertouch = aftertouch;
    this.orientation = orientation;
    this.bend = bend;
  }
 
  String toString(){
    String rtn = "Notes: ";
    for(int i = 0; i < notes.length; i++){
      rtn += "" + notes[i];
      if(i != (notes.length - 1))
        rtn += ", ";
    }
    rtn += " Orientation [" + orientation[0] + "," + orientation[1] +"]";
    rtn += " Aftertouch: " + aftertouch + " Bend: " + bend; 
    return rtn;  
  }
}
