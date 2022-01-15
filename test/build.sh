#/bin/bash
cd tree-sitter-cpp
../tree-sitter-graph/target/debug/tree-sitter-graph ../cpp_graph.tsg ../cpp_graph.hpp | awk -f ../cpp_graph.awk | dot -Tpdf -o ../cpp_graph.pdf
