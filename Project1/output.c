#include <stdio.h>

int main() {
    // some comment with number 123'534'534 0x34'33'23

    /* multi line comment 0x34'23'45
        123'433
    123'455*/

   /*
        //123'456
        123'456
        //0x67'AF
   */

  // /*
    123456;
  // */ fsdf 123'456  

    // hex numbers
    0xBB76;
    0x1AF5;
    0x1A45;
    0x12BC;
    0xAAAA;

    //small a-f
    0xbcaf;
    0x1cef;
    0xbc1f;
    0x12ef;

    //dec number
   123456789;
   1234543;


    //strings
   const char * text = "My number is 123'456'789";
   const char* another_text = "My hexadecimal number is 0x1A'F4'56";

    //char
    char a = '0';
    'A';

   printf("%s 123'456", text);

   123;"test123'456";

   // let's do some operations on numbers
    int b = a + 0x5;
    if (b + a == 123534) {
        a = 0x12AF;
    }
}
