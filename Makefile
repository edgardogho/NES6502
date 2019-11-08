objs := main.o
out := unlam.nes

all: $(out)

clean:
	rm -f $(objs) $(out)

.PHONY: all clean

# Assemble

%.o: %.s
	ca65 $< -o $@ -l list.lst

main.o: main.s

# Link

unlam.nes: link.x $(objs)
	ld65 -C link.x $(objs) -o $@
