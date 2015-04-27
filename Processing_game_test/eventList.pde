class eventList {
  ArrayList<gameEvent> list;
  eventList() {
    list = new ArrayList<gameEvent>();
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
    for(gameEvent e : list){
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
