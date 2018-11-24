# Here we define the type of CodeWord and the related methods for this type
# This definition determines the behavior and performance of all the other functions and types

_NI(m) = error("Not implemented: $m") # taken straight from LightGraphs package.

# This is an important choice (from performance perspective)
"  TheIntegerType is the integer type that is used for enumerating the vertices of combinatorial codes and simplicial complexes"
TheIntegerType=Int16 #

" CodeWord is the type ised to encode sets of vertices (used throughout this package). Currently,  CodeWord=Set{TheIntegerType}"
const CodeWord = Set{TheIntegerType}  # We currently encode sets via sparse sets of signed integers -- this optimizes memory usage, but not speed
# We could have used different methods of defining sets in Julia.
# For example we could have used IntSet, that would have optimized speed over memory...
# Another sensible option might be the sparse boolean arrays (in this case the subset, in and some other "elementary" functions would have to be re-written to work with this type)


" emptyset is the representation of the emptyset of the type CodeWord, i.e. emptyset=CodeWord([]) "
const emptyset=CodeWord([]) # This definition should agree with the CodeWord type

function show(io::IO, c::Set{T}) where {T<:Integer}
    if isempty(c)
        print(io, "emptyset")
    else
        print(io, join(sort(collect(c)), " "))
    end
end


" MaximalHomologicalDimension=8 This is the maximal homological dimension allowed by certain memory-intensive  methods that are computing too many faces. This is used as a precaution against crushing when demanding too much memory"
const MaximalHomologicalDimension=8;


"  PersistenceIntervalsType=Array{Array{Real,2},1} is a type used for keeping track of persistent intervals "

const SingleDimensionPersistenceIntervalsType=Matrix{Float64}
const PersistenceIntervalsType=Array{SingleDimensionPersistenceIntervalsType,1}

"""
function show(P::PersistenceIntervalsType);
This prints out the appropriate persistence intervals
"""
function show(P::PersistenceIntervalsType);
 println("Persistence intervals up to dimension=$(length(P)-1)");
 for d=0:length(P)-1
   print_with_color(:green, "d= $d"); println();
   if isempty(P[d+1])
       print_with_color(:green, "no intervals");println();
   else
       for l=1:size(P[d+1],1)
            print_with_color(:blue, "birth=",P[d+1][l,1])
            print_with_color(:red, "   death=",P[d+1][l,2]); println()
       end
   end
   print_with_color(:green,"-------------") ; println();
end
end



################################################################################
### Abstract type and general utility function definitions
################################################################################
"""
    abstract type AbstractFiniteSetCollection{T<:Integer}

Abstract supertype for concrete implementations of Combinatorial Codes and Simplicial
Complexes, or any other collection of finite sets (of integers). See also
[CombinatorialCode](@ref) and [SimplicialComplex](@ref)
"""
abstract type AbstractFiniteSetCollection{T<:Integer} end

################################################################################
### Generic method implementations
################################################################################

# generic, inefficient equality operator. Depends on iteration functions defined
# for C1 and C2
==(C1::AbstractFiniteSetCollection, C2::AbstractFiniteSetCollection) = Set(map(Set,C1)) == Set(map(Set,C2))

"""
    matrix_form(collection)

A `BitMatrix` with one row for every element of `collection`. Each row is a
logical index to the array `collect(vertices(C))`.
"""
function matrix_form(C::AbstractFiniteSetCollection)
    V = collect(vertices(C))
    M = falses(length(C), length(V))
    for (i,c) in enumerate(C)
        M[i,indexin(collect(c), V)] = true
    end
    return M
end

"""
    isvoid(collection)

`true` if the collection has no elements
"""
isvoid(C::AbstractFiniteSetCollection) = length(C) == 0

"""
    isirrelevant

`true` if the collection contains only the empty set.
"""
isirrelevant(C::AbstractFiniteSetCollection) = length(C) == 1 && [] in C

################################################################################
### Iteration functions
################################################################################

# iterating over a collection C, as in a loop "for c in C ...", should yield Set{T}s, where
# T is the vertex type of C.
eltype(::Type{AbstractFiniteSetCollection{T}}) where T = Set{T}

"""
    MaximalSetIterator{T<:AbstractFiniteSetCollection}

An object used for iterating over the maximal (by set inclusion) elements of a
collection. The typical user of this package will not need to explicitly
construct an object of this type; rather, the [`facets`](@ref) function
(equivalently, the [`max`](@ref) function) can be used anywhere an iterable
collection could be used.
"""
struct MaximalSetIterator{T<:AbstractFiniteSetCollection}
    collection::T
end
eltype(::Type{MaximalSetIterator{T}}) where {T<:AbstractFiniteSetCollection} = eltype(T)

"""
    facets(C::AbstractFiniteSetCollection)
    max(C::AbstractFiniteSetCollection)

An iterator over the maximal (by set inclusion) elements of collection `C`.
"""
facets(C::AbstractFiniteSetCollection) = MaximalSetIterator(C)
max(C::AbstractFiniteSetCollection) = facets(C)
