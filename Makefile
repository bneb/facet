# Facet Compositor — Build Targets
SALTC ?= saltc
MLIR_OUT ?= /tmp/facet_build

.PHONY: test verify demo clean bench-raster demo-tiger rec-tiger check

# Compile and type-check all modules. Reports Z3 proof coverage.
test:
	@mkdir -p $(MLIR_OUT)
	@echo "=== raster ==="
	@$(SALTC) raster/raster.salt --lib -o /dev/null
	@echo "=== test_raster ==="
	@$(SALTC) raster/test_raster.salt --lib -o /dev/null
	@echo "=== compositor ==="
	@$(SALTC) compositor/test_compositor.salt --lib -o /dev/null
	@echo "=== ui ==="
	@$(SALTC) ui/test_ui.salt --lib -o /dev/null

# Strict CI target — fails if any Z3 check is deferred to runtime.
verify:
	@mkdir -p $(MLIR_OUT)
	@$(SALTC) raster/raster.salt --lib --deny-deferred -o /dev/null

check: test

bench-raster:
	@mkdir -p $(MLIR_OUT)
	$(SALTC) raster/bench_raster.salt --lib --release -o $(MLIR_OUT)/bench_raster.mlir

demo-tiger:
	@mkdir -p $(MLIR_OUT)
	$(SALTC) raster/demo_tiger.salt --lib --release -o $(MLIR_OUT)/demo_tiger.mlir

rec-tiger:
	@mkdir -p $(MLIR_OUT)
	$(SALTC) raster/rec_tiger.salt --lib --release -o $(MLIR_OUT)/rec_tiger.mlir

clean:
	rm -rf $(MLIR_OUT)
