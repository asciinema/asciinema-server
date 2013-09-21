#include <stdio.h>
#include <libtsm.h>

#define READ_BUF_SIZE 16 * 1024

static int RGB_LEVELS[6] = { 0x00, 0x5f, 0x87, 0xaf, 0xd7, 0xff };

struct tsm_screen_attr last_attr;
struct tsm_screen_attr *last_attr_ptr = &last_attr;


static int u8_wc_to_utf8(char *dest, uint32_t ch) {
    if (ch < 0x80) {
        dest[0] = (char)ch;
        return 1;
    }

    if (ch < 0x800) {
        dest[0] = (ch >> 6) | 0xC0;
        dest[1] = (ch & 0x3F) | 0x80;
        return 2;
    }

    if (ch < 0x10000) {
        dest[0] = (ch >> 12) | 0xE0;
        dest[1] = ((ch >> 6) & 0x3F) | 0x80;
        dest[2] = (ch & 0x3F) | 0x80;
        return 3;
    }

    if (ch < 0x110000) {
        dest[0] = (ch >> 18) | 0xF0;
        dest[1] = ((ch >> 12) & 0x3F) | 0x80;
        dest[2] = ((ch >> 6) & 0x3F) | 0x80;
        dest[3] = (ch & 0x3F) | 0x80;
        return 4;
    }

    return 0;
}

void check_err(int err, const char *message) {
    if (err) {
        printf("%s\n", message);
        exit(1);
    }
}

void write_cb(struct tsm_vte *vte, const char *u8, size_t len, void *data) {}

int prepare_cb(struct tsm_screen *con, void *data) {
    int *line = (int *)data;

    *line = -1;
    printf("[");

    return 0;
}

void print_char(const uint32_t *ch) {
    char str[5];
    int size;

    if (*ch == 0) {
        printf(" ");
    } else if (*ch == '"') {
        printf("\\\"");
    } else if (*ch == '\\') {
        printf("\\\\");
    } else {
        size = u8_wc_to_utf8(str, *ch);
        if (size > 0) {
            str[size] = 0;
            printf("%s", str);
        } else {
            printf("?");
        }
    }
}

int get_rgb_index(int value) {
    int i;

    for (i=0; i<6; i++) {
        if (RGB_LEVELS[i] == value) return i;
    }

    return -1;
}

int get_rgb_color(int r, int g, int b) {
    if (r == g && g == b && (r - 8) % 10 == 0) {
        return 232 + (r - 8) / 10;
    } else {
        return 16 + get_rgb_index(r) * 36 + get_rgb_index(g) * 6 + get_rgb_index(b);
    }
}

int get_fg(const struct tsm_screen_attr *attr) {
    if (attr->fccode == -1) {
        return get_rgb_color(attr->fr, attr->fg, attr->fb);
    } else if (attr->fccode >= 0 && attr->fccode < 16) {
        return attr->fccode;
    } else {
        return -1;
    }
}

int get_bg(const struct tsm_screen_attr *attr) {
    if (attr->bccode == -1) {
        return get_rgb_color(attr->br, attr->bg, attr->bb);
    } else if (attr->bccode >= 0 && attr->bccode < 16) {
        return attr->bccode;
    } else {
        return -1;
    }
}

void print_attr(const struct tsm_screen_attr *attr) {
    bool comma_needed = false;
    int color_code;

    printf("{");

    color_code = get_fg(attr);
    if (color_code != -1) {
        printf("\"fg\":%d", color_code);
        comma_needed = true;
    }

    color_code = get_bg(attr);
    if (color_code != -1) {
        if (comma_needed) printf(",");
        printf("\"bg\":%d", color_code);
        comma_needed = true;
    }

    if (attr->bold) {
        if (comma_needed) printf(",");
        printf("\"bold\":true");
        comma_needed = true;
    }

    if (attr->underline) {
        if (comma_needed) printf(",");
        printf("\"underline\":true");
        comma_needed = true;
    }

    if (attr->inverse) {
        if (comma_needed) printf(",");
        printf("\"inverse\":true");
        comma_needed = true;
    }

    if (attr->blink) {
        if (comma_needed) printf(",");
        printf("\"blink\":true");
        comma_needed = true;
    }

    printf("}");
}

bool attr_eq(struct tsm_screen_attr *attr1, const struct tsm_screen_attr *attr2) {
    return attr1->fccode == attr2->fccode &&
        attr1->bccode == attr2->bccode &&
        attr1->fr == attr2->fr &&
        attr1->fg == attr2->fg &&
        attr1->fb == attr2->fb &&
        attr1->br == attr2->br &&
        attr1->bg == attr2->bg &&
        attr1->bb == attr2->bb &&
        attr1->bold == attr2->bold &&
        attr1->underline == attr2->underline &&
        attr1->inverse == attr2->inverse &&
        attr1->blink == attr2->blink;
}

void attr_cp(const struct tsm_screen_attr *src, struct tsm_screen_attr *dst) {
    memcpy((void *)dst, (const void *)src, sizeof(last_attr));
}

void close_cell() {
    printf("\",");
    print_attr(last_attr_ptr);
    printf("]");
}

void open_cell(const struct tsm_screen_attr *attr) {
    printf("[\"");
    attr_cp(attr, last_attr_ptr);
}

int draw_cb(struct tsm_screen *con, uint32_t id, const uint32_t *ch, size_t len,
            unsigned int width, unsigned int posx, unsigned int posy,
            const struct tsm_screen_attr *attr, void *data) {

    int *line = (int *)data;

    if (((signed int)posy) > *line) {
        if (*line >= 0) {
            close_cell();
            printf("],"); // close line
        }
        printf("["); // open line
        open_cell(attr);
    }

    *line = posy;

    if (width == 0) return 0;

    if (!(attr_eq(last_attr_ptr, attr))) {
        close_cell();
        printf(",");
        open_cell(attr);
    }

    print_char(ch);

    return 0;
}

int render_cb(struct tsm_screen *con, void *data) {
    int *line = (int *)data;

    if (*line >= 0) {
        close_cell();
        printf("]"); // close line
    }

    printf("]\n");

    return 0;
}

int main(int argc, char *argv[]) {
    int err;
    int i;
    struct tsm_screen *screen;
    struct tsm_vte *vte;
    int width, height;
    char *line = NULL;
    size_t size;
    unsigned int n;
    char *buffer = (char *) malloc(READ_BUF_SIZE);
    int line_n, cursor_x, cursor_y;
    char *cursor_visible;
    unsigned int flags;
    int m, read;

    width = atoi(argv[1]);
    height = atoi(argv[2]);

    err = tsm_screen_new(&screen, NULL, NULL);
    check_err(err, "can't create screen");

    err = tsm_screen_resize(screen, width, height);
    check_err(err, "can't resize screen");

    err = tsm_vte_new(&vte, screen, write_cb, NULL, NULL, NULL);
    check_err(err, "can't create vte");

    for (;;) {
        if (getline(&line, &size, stdin) == -1) break;

        char action = line[0];

        switch(action) {
            case 'd':
                if (getline(&line, &size, stdin) == -1) break;
                n = atoi(line);
                while (n > 0) {
                    if (n > READ_BUF_SIZE) {
                        m = READ_BUF_SIZE;
                    } else {
                        m = n;
                    }
                    read = fread(buffer, 1, m, stdin);
                    tsm_vte_input(vte, buffer, read);
                    n = n - read;
                }
                break;
            case 'p':
                tsm_screen_draw(screen, prepare_cb, draw_cb, render_cb, &line_n);
                break;
            case 'c':
                cursor_x = tsm_screen_get_cursor_x(screen);
                cursor_y = tsm_screen_get_cursor_y(screen);
                flags = tsm_screen_get_flags(screen);
                if (!(flags & TSM_SCREEN_HIDE_CURSOR)) {
                    cursor_visible = "true";
                } else {
                    cursor_visible = "false";
                }
                printf("{\"x\":%d,\"y\":%d,\"visible\":%s}\n", cursor_x, cursor_y, cursor_visible);

                break;
        }

        fflush(stdout);
    }

    return 0;
}
