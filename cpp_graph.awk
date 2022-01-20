#!/usr/bin/awk -f

# Goal: Parse the output of tree-sitter-graph and produce UML diagrams

# Note:
# - This is not supposed to **accurately** reflect the code
# - But will be good enough for presenting outlines of code design

# Plan:
# - [x] Produce proper UML nodes for classes with members
#       - [x] italics for abstruct classes
#       - [x] attributes (access, static, type, derived?)
#       - [x] methods (access, static, return type)
# - [ ] Produce proper class-relationship arrows
#       - [x] Inheritence
#       - [ ] Usage (aggregation, composition ***, dependency)
 
function class_label(node_name) {
    # Format class label if the passed graph node name is a class
    # This supposed nodes[node_name]["name"] has the class name
    if (nodes[node_name]["kind"] ~ /class/)
    {
        class = "<b>" format(nodes[node_name]["label"]) "</b>"
        if (nodes[node_name]["abstract"]) {
            class = "<i>" class "</i>"
        }
        return class
    }
    return ""
}

function access(node_name) {
    # Return access specifier representation for a member var/func
    if (nodes[node_name]["access"] ~ /public/) {
        return "+"
    } else if (nodes[node_name]["access"] ~ /private/) {
        return "-"
    } else if (nodes[node_name]["access"] ~ /protected/) {
        return "#"
    }
    return " "
}

function format_storage(node_name, string) {
    # Underline static member vars
    if (nodes[node_name]["storage"] ~ /static/) {
        return "<u>" string "</u>"
    } else {
        return string
    }
}

function format(string) {
    # Styles graph node text as HTML markup
    if (string ~ /".*"/) {
        # if a literal string, get rid of surrounding quotes
        string = substr(string, 2, length(string)-2)
    }
    # Get rid non-sense whitespace
    s = gsub(/\s+/," ", string)
    s = gsub(/\\n/,"", string)
    # Escape quotes
    s = gsub(/\\"/, "\"", string)
    # Order here is important, so pay attention
    s = gsub("&", "\\&amp;", string)
    s = gsub("<", "\\&lt;", string)
    s = gsub(">", "\\&gt;", string)
    return string
}

function edge_style(string) {
    # Assigns graph edge style using edge relationship type
    # string is empty if edge has no relatioship
    if (string == "\"has_member\"") {
        return " [style=dotted]"
    } else if (string == "\"parent\"") {
        return " [style=bold]"
    }
}

BEGIN {
    # Treat literal strings as a single column
    FPAT = "([^ ]+)|(\"[^\"]+\")"

    # How many edges we've processed
    edge_index = -1

    # Common configs
    mono_font = "ubuntu"
}

# A node will represent a class, and is an array with indices:
#    [
#        label : string,       -> contains formatted class/Template name
#        kind : string,        -> node kind
#        type : string,        -> the c++ type of this node if an attribute, empty otherwise
#        parent : string,      -> parent node if an attribute node, empty otherwise
#        member_vars : string, -> list member variables as one record field
#        member_meth : string, -> list member methods as one record field
#        abstract : string,    -> pure virtual class ("true" if so, empty otherwise)
#        show : string,        -> wether to show this node on the graph (classes are shown regardless)
#    ]

/^node [0-9]+/ {
    # This is a start of node definition
    node_index++
    # Store node index
    node_name = "node_" $2
}

# Blindly pull all properties into the array
/^\s+([a-z_]+):/ {
    # this is a property of the node, store it where it belongs
    prop = substr($1,0,length($1)-1)
    nodes[node_name][prop] = $2

    # Check alias nodes and copy name to label
    if ($1 ~ /name/) {
        if ($2 in node_names) {
            # name is found again, this node is an alias node to node_names[$2]
            nodes[node_name]["alias"] = node_names[$2]
        }
        node_names[$2] = node_name
        nodes[node_name]["label"] = nodes[node_name]["name"]
    }

    # Add template parameters for template nodes
    if ($1 ~ /parameters/) {
        nodes[node_name]["label"] = "\"template" substr(nodes[node_name]["parameters"],2,length(nodes[node_name]["parameters"])-2) " " substr(nodes[node_name]["name"], 2, length(nodes[node_name]["name"])-2) "\""
    }

    # Add template args for template instantiations
    if ($1 ~ /arguments/) {
        nodes[node_name]["label"] = "\"" substr(nodes[node_name]["name"], 2, length(nodes[node_name]["name"])-2) substr(nodes[node_name]["arguments"],2,length(nodes[node_name]["arguments"])-2) "\""
    }
}

# An edge has: (source : string, sink : string, relationship : string)

/^edge\s+[0-9]+\s+->\s+[0-9]+/ {
    # This is a start of edge definition
    edge_index++
    edges[edge_index][0] = $2
    edges[edge_index][1] = $4
}

/relationship:/ {
    # Node relationship kind
    edges[edge_index][2] = $2
}

END {
    # Sort out has_member relationship
    for(i = 0; i <= edge_index; i++) {
        parent = "node_" edges[i][0]
        child = "node_" edges[i][1]
        nodes[parent]["show"] = "true"
        if (edges[i][2] ~ /has_member/) {
            if (nodes[child]["kind"] ~ /member_function/) {
                entry = access(child) " " format(nodes[child]["label"]) " : " format(nodes[child]["type"])
                entry = format_storage(child, entry)
                nodes[parent]["member_funs"] = nodes[parent]["member_funs"] entry "<br align=\"left\"/>"
                # Mark the class as abstract if it has at least one pure virtual member
                if (nodes[child]["abstract"]) {
                    nodes[parent]["abstract"] = "true"
                }
            } else {
                entry = access(child)  " " format(nodes[child]["label"]) " : " format(nodes[child]["type"])
                entry = format_storage(child, entry)
                nodes[parent]["member_vars"] = nodes[parent]["member_vars"] entry "<br align=\"left\"/>"
                # Especially, for member variables, draw aggregation relationships
                child_type_node = nodes[child]["type"]
                for(node in nodes) {
                    if (nodes[node]["name"] == nodes[child]["type"]) {
                        child_type_node = node
                    }
                }
                nodes[child_type_node]["show"] = "true"
                if (nodes[child_type_node]["label"] == "") {
                    nodes[child_type_node]["label"] = nodes[child]["type"]
                }
                agg_edges[parent child_type_node] = "\t" parent " -> " child_type_node " [labeldistance=1.2, arrowhead=\"odiamond\", headlabel=\"1\", taillabel=\"1\"]"
            }
        }
    }

    # Sort out template instantiations
    for(node in nodes) {
        name = substr(nodes[node]["name"], 2, length(nodes[node]["name"])-2)
        if (nodes[node]["kind"] ~ /template_type/ && nodes[node]["show"]) {
            nodes[name "_root"]["name"] = nodes[node]["name"]
            nodes[name "_root"]["label"] = nodes[node]["name"]
            nodes[name "_root"]["instantiations"] = nodes[name "_root"]["instantiations"] ";" node
        }
        if (nodes[name "_root"]["instantiations"]) {
            nodes[name "_root"]["show"] = "true"
        }
    }

    # Preparing the diagram

    # 1.0 Subgraphs represent name spaces

    # Diagram
    print "digraph DR {"
    print "\tcompound=true; nodesep=.75;"
    for(node in nodes) {
        # Skip drawing alias nodes
        if (nodes[node]["alias"]) {
            nodes[node]["show"] = ""
        }
        # Draw class nodes
        if (nodes[node]["namespace"]) {
            if (nodes[node]["kind"] ~ /class/) {
                members = nodes[node]["member_vars"] ? " | " nodes[node]["member_vars"] : ""
                methods = nodes[node]["member_funs"] ? " | " nodes[node]["member_funs"] : ""
                subgraphs[nodes[node]["namespace"]] = subgraphs[nodes[node]["namespace"]] node " [ label = < {" class_label(node) members methods "} >, shape=record, fontname=" mono_font "]"
            } else  if (nodes[node]["show"]){
                subgraphs[nodes[node]["namespace"]] = subgraphs[nodes[node]["namespace"]] node " [ label = < " format(nodes[node]["label"]) ">, shape=rect, fontname=" mono_font "]"
            }
        } else {
            if (nodes[node]["kind"] ~ /class/) {
                print node, "[ label = < {" class_label(node) " | " nodes[node]["member_vars"] " | " nodes[node]["member_funs"] "} >, shape=record, fontname=" mono_font "]"
            } else  if (nodes[node]["show"]){
                print node, "[ label = < " format(nodes[node]["label"]) ">, shape=rect, fontname=" mono_font "]"
            }
        }
    }
    for(sg in subgraphs) {
        print "subgraph cluster_" substr(sg, 2, length(sg)-2), "{"
        print "style=filled; color=lightgrey;"
        print "label =", sg
        print subgraphs[sg]
        print "}"
    }
    # Edges from original graph (Inheritance only)
    for(i = 0; i <= edge_index; i++) {
        # Firgure out the real parent graph node
        parent_node = "node_" edges[i][0]
        if (nodes[parent_node]["alias"]) {
            parent_node = nodes[parent_node]["alias"]
        }
        if (edges[i][2] ~ /parent/) {
            print "\t" parent_node " -> node_" edges[i][1] "[labeldistance=1.2, arrowhead=\"empty\"]"
        }
    }
    # Edges for template instatiations (here considered a composition relationship)
    for(node in nodes) {
        if (node ~ /_root/) {
            # if a template root node has some instations, show it and link it to its instantiations
            if(nodes[node]["instantiations"]) {
                split(nodes[node]["instantiations"], insts, ";")
                for (idx in insts) {
                    if (insts[idx]) {
                        print "\t" node " -> " insts[idx] "[labeldistance=1.2, arrowhead=\"diamond\", headlabel=\"1\", taillabel=\"1\"]"
                    }
                }
            }
        }
    }
    # Aggregation edges   
    for (idx in agg_edges) {
        print agg_edges[idx]
    }
    print "}"
}
