CPPFLAGS += -std=c++11 -W -Wall -g -O3 -I include
CPPFLAGS += -Wno-unused-parameter

SHELL	= /bin/bash

LDLIBS += -ljpeg
LDLIBS += -ltbb

all: reference_tools user_simulator

bin/% : src/%.cpp
	mkdir -p $(dir $@)
	$(CXX) $(CPPFLAGS) $< -o $@ $(LDFLAGS) $(LDLIBS)

bin/user/simulator: include/user_simulator.hpp include/graphs/user_heat.hpp

reference_tools : bin/ref/simulator bin/tools/generate_heat_rect

user_simulator : bin/user/simulator

bin w records results:
	mkdir -p $@

.SECONDARY:
.DELETE_ON_ERROR:

UPD	?= 1024
SUB	?= 4
SPA	?= 8
LOG	?= 0

w/heat%_rect.graph: | bin/tools/generate_heat_rect w
	bin/tools/generate_heat_rect $* $(UPD) $(SUB) $(SPA) > $@

w/%.ref.mjpeg: w/%.graph | bin/ref/simulator
	(time $| --log-level $(LOG) $< $(@:.mjpeg=.stats) $@) 2>&1 | tee $(@:.mjpeg=.log)

w/%.user.mjpeg: w/%.graph bin/user/simulator
	(time bin/user/simulator --log-level $(LOG) $< $(@:.mjpeg=.stats) $@) 2>&1 | tee $(@:.mjpeg=_$(LOG).log)

results/%.pass: w/%.ref.mjpeg w/%.user.mjpeg | results
	-diff -q $^
	-diff -q w/$*.ref.stats w/$*.user.stats

%.gprof: %
	gprof $* > $@
	gvim $@

test:	results/heat128_rect.pass

.PHONY: pdf
pdf:	results/$(PLATFORM).pdf

PLATFORM ?= i5_3337U-HD4000

results/$(PLATFORM).pdf: w/$(PLATFORM).dat plot.gnu include/graphs/user_heat.hpp include/user_simulator.hpp | results
	gnuplot -e "set xlabel 'scale'; set ylabel 'time'" \
		-e "set logscale x; set logscale y" \
		-e "filename='$<'" -e "cols=$(shell head -n 1 $< | sed 's/"[^"]*"/w/g' | wc -w)" ./plot.gnu > $@

#SEQ	:= $(shell for i in `seq 2 7`; do echo $$((2 ** i)); done)
SEQ	:= $(shell seq 10 10 100)

# Records and data generation

TIME	:= $(shell date +%y%m%d-%H%M%S)

w/$(PLATFORM).dat: w/$(PLATFORM)-x.dat records/$(TIME)-$(PLATFORM).dat include/graphs/user_heat.hpp include/user_simulator.hpp | results
	echo "scale `ls records/*-$(PLATFORM).dat | sed 's/.*\/\([0-9]*-[0-9]*\).*/\1/' | xargs`" > $@
	paste w/$(PLATFORM)-x.dat `ls records/*-$(PLATFORM).dat` | sed 's/^\t/NaN\t/;s/\s\s/\tNaN\t/g;s/\s\s/\tNan\t/g' >> $@

w/$(PLATFORM)-x.dat: | w
	echo $(SEQ) | tr ' ' '\n' > $@

w/$(PLATFORM).time: bin/execute_puzzle $(foreach i,$(SEQ),w/$i.user.time)
	for f in $(filter-out $<,$^); do ; done 2>&1 | tee $@

w/%.real: w/%.time
	cat $< | grep -E 'Begin execution|Finished execution' | awk '{print $$2}' | sed 's/,//' | paste - - | sed 's/^/-/;s/\s/+/' | bc > $@
