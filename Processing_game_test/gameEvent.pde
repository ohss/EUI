class gameEvent {
  Boolean hasBeenFullfilled;
  Boolean isNote;
  Note note;
  ccEvent cc;
  gameEvent(Note note, ccEvent cc) {
    if(note != null){
      this.note = note;
      this.cc = null;
      isNote = true;
    }else if(cc != null){
      this.cc = cc;
      this.note = null;
      isNote = false;
    }
    this.hasBeenFullfilled = false;
  }

  public String toString(){
    if(note != null)
      return(note.pitch() + ":" +note.name() + " " + this.hasBeenFullfilled);
    else if (cc != null){
      String cclist = "";
        switch(this.cc.type){
          case AFTERTOUCH:
            cclist += "Aftertouch: " + cc.value;
            break;
          case CC:
            cclist += "CC: " + cc.number + ":" + cc.value;
            break;
          case PITCHBEND:
             cclist += "Pitchbend: " + cc.value;
             break;
        }
      return(cclist + " " + this.hasBeenFullfilled);
    }
    return("");
  }

  public Boolean pitchEquals(gameEvent e){
    if(this.note != null && e.note != null){
      if(this.note.pitch() == e.note.pitch()){
        return(true);
      }
    }
    return(false);
  }
  public Boolean ccEquals(gameEvent e){
    if(this.cc != null && e.cc != null){
      if(this.cc.type == e.cc.type && this.cc.number == e.cc.number && Math.abs(this.cc.value) <= Math.abs(e.cc.value)){
        //hasBeenFullfilled = true;
        return(true);
      }
    }
    return(false);
  }

  public void match(){
    this.hasBeenFullfilled = true;
  }
  public Boolean matched(){
    return(hasBeenFullfilled);
  }


  /**
   * Update the CC max value of the game Event
   */
  public Boolean update(gameEvent e){
    if(this.cc != null && e.cc != null){
      if(this.ccEquals(e)){
        //println("Updating CC value");
        this.cc.value = e.cc.value;
        return(true);
      }else if(this.cc.type == e.cc.type && this.cc.number == e.cc.number){
        //println("Smaller not updating");
        return(true);
      }else{
        return(false);
      }
    }else{
      return(false);
    }
  }
}
