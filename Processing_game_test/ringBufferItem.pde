public static final float FILTER_COEF = 10.0;

class ringBufferItem{
  int index;
  int size;
  int[] data;
  int threshold;
  int aftertouchCounter;
  boolean triggered;

  ringBufferItem(int size){
    this.index = -1;
    this.size = size;
    this.threshold = 0;
    this.aftertouchCounter = 0;
    this.triggered = false;
    this.data = new int[size];
    for(int i = 0; i < data.length; i++){
      data[i] = 0;
    }
  }
  void add(int val){
    this.index = (this.index + 1) % size;
    data[this.index] = val;
  }

  void addFiltered(int val){
    if(index >= 0){
      int old = this.data[index];
      this.index = (this.index + 1) % size;
      data[this.index] = (int)Math.round((val+old*FILTER_COEF)/(FILTER_COEF+1));
    }else
      this.add(val);
  }

  void trigger(){
    this.triggered = true;
    this.threshold = getRawCurrent();
    this.aftertouchCounter = 0;
  }

  void unTrigger(){
    this.triggered = false;
    this.threshold = 0;
    this.aftertouchCounter = 0;
  }
  Boolean aftertouch(){
    if(this.aftertouchCounter < AFTER_TOUCH_ITER_COUNT){
      this.threshold = (this.threshold + getRawCurrent())/2;
      this.aftertouchCounter++;
      return false;
    }else{
      return true;
    }
  }
  Boolean pitchbend(){
    if(this.aftertouchCounter < PITCHBEND_ITER_COUNT){
      this.threshold = (this.threshold + getRawCurrent())/2;
      this.aftertouchCounter++;
      return false;
    }else{
      return true;
    }
  }

  void updateThreshold(){
    this.threshold = (this.threshold + getRawCurrent())/2;
  }

  int getMedian(){
    int[] sorted = sort(data);
    return(sorted[(size/2)-1]);
  }

  int getRawCurrent(){
    if(index >= 0)
      return this.data[this.index];
    else
      return 0;
  }

  int getCurrent(){
    int value = 0;
    int median = getMedian();
    for(int i = 0; i < (size/2); i++){
      if((this.index - i) >= 0){
        value += data[(this.index - i) % size] - median;
      }else if (this.index >= 0){
        value += data[(size - this.index - i ) % size] - median;
      }else{
        return(0);
      }
    }
    return(value/(size/2));
  }
}
