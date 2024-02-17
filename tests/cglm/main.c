#include <stdio.h>

#include "cglm/cglm.h"

int main() {
    vec3 inAngles;
    inAngles[0] = glm_rad(-45.0f); /* X angle */
    inAngles[1] = glm_rad(88.0f);  /* Y angle */
    inAngles[2] = glm_rad(18.0f);  /* Z angle */
    printf("Hello, World\n");
    return 0;
}