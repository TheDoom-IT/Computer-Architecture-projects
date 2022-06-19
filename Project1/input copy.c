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
    123'456;
  // */ fsdf 123'456  

    // hex numbers
    0xBB'76;
    0x1A'F5;
    0x1A'45;
    0x12'BC;
    0xAA'AA;

    //small a-f
    0xbc'af;
    0x1c'ef;
    0xbc'1f;
    0x12'ef;

    //dec number
   123'456'789;
   1'2'34'5'4'3;


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
    if (b + a == 123'534) {
        a = 0x12'AF;
    }
}
