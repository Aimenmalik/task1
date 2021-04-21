#include "print.h"

void kernel_main() {
    print_clear();
    print_set_color(PRINT_COLOR_YELLOW, PRINT_COLOR_BLACK);
    print_str("AA !!!        AA  (())       (())    ^^^^^^^^   WWWWWWWWWWWWWW\n AA  !!!       AA  !!!        (())    ^^^^            WW\n   AA   !!!      AA  (())      (())    ^^              WW\n   AA    !!!     AA  (())       (())    ^^                WW\n   AA     !!!    AA  (())       (())       ^^^^^         WW\n   AA      !!!   AA    (((((())))))      ^^^^^^^^^          WW\n");
}