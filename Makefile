objs := mario.o
out := mario.nes

all: $(out)

clean:
	rm -f $(objs) $(out)

.PHONY: all clean

# Assemble

%.o: %.s
	ca65 $< -o $@ -l mario.lst

mario.o: mario.s

# Link

mario.nes: link.x $(objs)
	ld65 -C link.x $(objs) -o $@
