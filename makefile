ROOT=$(shell pwd)

all::

clean::

dist_clean:: clean


EMMC_OPTIM_FLAGS=\
-O3 \
-s DISABLE_EXCEPTION_CATCHING=0

EMMC_DEBUG_FLAGS=\
#-g

EMMC_THREADS_FLAGS=
#-D HAVE_PTHREAD
#-s USE_PTHREADS=1

EMMC_MEMORY_FLAGS=\
-s ALLOW_MEMORY_GROWTH=1
#-s TOTAL_MEMORY=268435456 

EMCC=emcc \
-std=gnu++14 \
-stdlib=libc++ \
--bind \
$(EMMC_OPTIM_FLAGS) \
$(EMMC_DEBUG_FLAGS) \
$(EMMC_THREADS_FLAGS) \
$(EMMC_MEMORY_FLAGS)


##
## .CC => .O (javascript)
##

SOURCES=$(shell find src -name "*.cc" | grep -v _test.cc | sed -e's/^.*\///')
OBJECTS=$(SOURCES:%.cc=obj/%.o)

EMCC_LC0=$(EMCC) -I src

obj/%.o:: src/utils/%.cc
	@mkdir -p obj
	$(EMCC_LC0) $< -o $@

obj/%.o: src/chess/%.cc
	@mkdir -p obj
	$(EMCC_LC0) $< -o $@

obj/%.o: src/proto/%.cc
	@mkdir -p obj
	$(EMCC_LC0) $< -o $@

obj/%.o: src/syzygy/%.cc
	@mkdir -p obj
	$(EMCC_LC0) $< -o $@

obj/%.o: src/mcts/%.cc
	@mkdir -p obj
	$(EMCC_LC0) $< -o $@

obj/%.o: src/neural/%.cc
	@mkdir -p obj
	$(EMCC_LC0) $< -o $@

obj/%.o: src/neural/blas/%.cc
	@mkdir -p obj
	$(EMCC_LC0) $< -o $@

obj/%.o: src/benchmark/%.cc
	@mkdir -p obj
	$(EMCC_LC0) $< -o $@

obj/%.o: src/%.cc
	@mkdir -p obj
	$(EMCC_LC0) $< -o $@

clean::
	rm -f $(OBJECTS)

##
## BLAS (debug)
##

#
#WEIGHTS_FILE=weights/weights_9155.txt.gz
#TEST_FILE=weights/test_9155.txt.gz
#
#weights.txt: $(WEIGHTS_FILE)
#	gunzip -c $< > $@
#
#www/weights.txt.gz : $(WEIGHTS_FILE)
#	cp $< $@
#
#www/test.txt.gz : $(TEST_FILE)
#	cp $< $@
#
#clean::
#	rm -f weights.txt
#
#dist_clean::
#	rm -f www/weights.txt.gz www/test.txt.gz
#
#$(TARGETS): $(OBJECTS) weights.txt $(MAIN_JS)
#	$(EMCC) --preload-file weights.txt --pre-js $(MAIN_JS) -o www/lc0.js $(OBJECTS)


##
## Bundled networks
##

WEIGHTS_LIST=weights/bundled.txt

WEIGHTS_FILES=$(shell cat $(WEIGHTS_LIST))

COPIED_WEIGHTS_FILES=$(WEIGHTS_FILES:%=www/%)

all:: www/networks.txt $(COPIED_WEIGHTS_FILES)

$(WEIGHTS_FILES:%=weights/%):
	cd weights && make

www/%: weights/% $(WEIGHTS_LIST)
	cp $< $@

www/networks.txt: $(WEIGHTS_LIST)
	cp $< $@

dist_clean::
	rm -f www/networks.txt $(COPIED_WEIGHTS_FILES)



##
## protobuf
##

all:: www/pb.proto

www/pb.proto:  libs/lczero-common/proto/net.proto
	cp $< $@

dist_clean::
	rm -f www/pb.proto


##
## LINK
##

TARGETS=\
www/lc0.js \
www/lc0.wasm

ADDITIONAL_OBJECTS=\
www/lc0.wast \
www/lc0.data \
www/lc0.html

MAIN_JS=main.js

all:: $(TARGETS)

dist_clean::
	rm -f $(TARGETS) $(ADDITIONAL_OBJECTS)

$(TARGETS): $(OBJECTS) $(MAIN_JS)
	$(EMCC) --pre-js $(MAIN_JS) -o www/lc0.js $(OBJECTS)


run_server:
	cd $(ROOT)/www && python -m SimpleHTTPServer 8000

run_test:
	'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'  http://localhost:8000/engine.html
	
