# Diagrams for C++ header files

> Note: This is a PoC project; Issues will drive the development

### What's this all about

We strive for a tool to generate elegant UML-like class/object diagrams for C++ header files.

### Dependencies

You need the following software packages to make this work:

0. [One of the AWKs](https://www.gnu.org/software/gawk/) and [Graphviz](https://graphviz.org/) or anything which understands DOT Diagrams
1. Make sure to: `git clone --recurse-submodules https://github.com/FoamScience/cpp-header-diagrams`
2. NodeJS; Please install the LTS version using [NVM](https://github.com/nvm-sh/nvm)
3. Tree-Sitter CLI, which can be installed with `npm install -g tree-sitter-cli`
4. The C++ grammar for Tree-Sitter (included as a sub-module)
   - Please run `npm install` in the [tree-sitter-cpp directory](tree-sitter-cpp)
5. [tree-sitter-graph](https://github.com/tree-sitter/tree-sitter-graph), which is a Rust lib/binary, you'll have to get [Cargo](https://doc.rust-lang.org/cargo/getting-started/installation.html)

### A Quick guide for Devs/Users

> Here, developing basically means text-editing and tree-parsing

A one-liner for the impatient (on a *Nix machine):
```bash
# All tree-sitter-graph commands must run inside tree-sitter-cpp
cd tree-sitter-cpp
tree-sitter-graph ../cpp_graph.tsg ../cpp_graph.hpp | awk -f ../cpp_graph.awk | dot -Tpdf -o ../cpp_graph.pdf
```

#### Step 1: Parse your header file

The very first step is to make sure the Tree-Sitter grammar can parse your header file:
```bash
# Should not throw errors, but,
# we might be able to construct a diagram even if it does
tree-sitter parse test.hpp
```

> NeoVIM users can install the [TSPlayground](https://github.com/nvim-treesitter/playground) for better visualisation of the parsed tree.

If the previous command throws an `ERROR` and you're sure your header is valid C++, you are
encouraged to report bugs here or at [tree-sitter-cpp](https://github.com/tree-sitter/tree-sitter-cpp).

#### Stop 2: Produce a graph

To produce a graph for your header file:
```bash
# In tree-sitter-cpp
tree-sitter-graph ../cpp_graph.tsg ../cpp_graph.hpp
```

`cpp_graph.tsg` is what drives graph nodes creation and linking. It relies on the parsed file tree
to produce nodes for C++ entities with their properties.

It basically consists of stanzas of the form:
```
(
    target_tree_sitter_query
)
{
    ;; actions
}
```

Head to [the docs](https://docs.rs/tree-sitter-graph/latest/tree_sitter_graph/reference/index.html) to make sense of the simplistic DSL it defines.

> Note that the only relationship output by the graph is "inheritance", everything else is derived later

#### 3. Convert the graph into a DOT diagram

This step is actually just "text-editing" the graphs. 
The `cpp_graph.awk` AWK script, takes the graph from the previous step as input and returns a DOT-compliant diagram which looks like UML.

> The DOT language allows HTML node labels.

### Important nodes

- Diagrams won't **accurately** represent code constructs to the letter, we'll relax some rules for
    better presentable diagrams (Eg. where are the constructors?)
- Tree-Sitter query patterns are quite powerful, but as the graph DSL is young, there are some areas we must postpone to the AWK step
