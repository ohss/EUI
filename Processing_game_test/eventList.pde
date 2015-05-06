class eventList {
  ArrayList<gameEvent> list;
  eventList() {
    list = new ArrayList<gameEvent>();
  }

  public Targets getTargets(){
    ArrayList<Integer> notes = new ArrayList<Integer>();
    int aftertouch = 0;
    int bend = 0;
    int[] orientation = {0,0};
    for(gameEvent n : list){
      if(n.note != null){
        int relativePitch = n.note.relativePitch() % 12;
        int noteIndex = java.util.Arrays.binarySearch(scale, relativePitch);
        if(noteIndex >= 0){
          //println("Note + " + relativePitch + " hasIndex " + noteIndex);
          notes.add(new Integer(noteIndex));
        }
      }else if(n.cc != null){
        switch(n.cc.type){
          case AFTERTOUCH: aftertouch = n.cc.value; break;
          case PITCHBEND: bend = n.cc.value; break;
          case CC:
            if(n.cc.number == 1)
              orientation[0] = n.cc.value;
            if(n.cc.number == 2)
              orientation[1] = n.cc.value;
        }
      }
    }
    int[] rtnNotes = new int[notes.size()];
    for(int i = 0; i < rtnNotes.length; i++){
      rtnNotes[i] = notes.get(i).intValue();
    }
    return new Targets(rtnNotes, aftertouch, orientation, bend);
  }

  public Boolean add(gameEvent e){
    if(e.note != null){
      list.add(e);
    }else{
      //Check if the CC exists and needs to be updated
      Boolean isNew = true;
      for(gameEvent n: list){
        if(n.update(e)){
          //println("CC already in list updating.");
          isNew = false;
          break;
        }
      }
      if(isNew){
        //println("Adding new CC");
        list.add(e);
      }
    }
    return(true);
  }

  public void remove(gameEvent e){

    Boolean hasNotes = false;
    // Remove the note
    for(gameEvent n : list){
      if(n.pitchEquals(e)){
        list.remove(n);
        break;
      }
    }
    //Check if this was the last note
    for(gameEvent n : list){
      if(n.isNote){
        hasNotes = true;
        break;
      }
    }
    if(!hasNotes){
      this.list.clear();
    }
  }

  public gameEvent contains(gameEvent e){
    for(gameEvent n : list){
      if(n.pitchEquals(e) || n.ccEquals(e)){
        return(n);
      }
    }
    return(null);
  }

  public String toString(){
    String returnStr = "";
    for(int i = 0; i < list.size(); i++){
      returnStr += "Event [" + i + "] " + list.get(i).toString() + "\n";
    }
    return(returnStr);
  }

  public Boolean hasBeenCompletelyFullfilled(){
    Boolean isComplete = true;
    ArrayList<gameEvent> copyList = (ArrayList<gameEvent>)list.clone();
    for(gameEvent e : copyList){
      if(!e.matched()){
        isComplete = false;
        break;
      }
    }
    return(isComplete);
  }

  public void clear(){
    list.clear();
  }
  public int size(){
    return list.size();
  }
}
