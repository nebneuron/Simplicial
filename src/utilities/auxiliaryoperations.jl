# misc utility functions

# memory performance functions
"""
    smallest_int_type(ints...)

Return the smallest integer type that can store all the given integers.
"""
function smallest_int_type(ints...)
    types = [Int8, Int16, Int32, Int64]
    for T in types
        all(i -> typemin(T) <= i < typemax(T), ints) && return T
    end
end

"""
    smallest_uint_type(ints...)

Return the smallest unsigned integer type that can store all the given integers
"""
function smallest_uint_type(ints...)
    types = [UInt8, UInt16, UInt32, UInt64]
    for T in types
        all(i -> i < typemax(T), ints) && return T
    end
end

# sorting binary vectors and sets
"""
    lessequal_GrRevLex(a, b)

True if ``a <=_GrRevLex b``. See [graded reverse lexicographic
order](https://en.wikipedia.org/wiki/Monomial_order#Graded_reverse_lexicographic_order).

Can be used to `sortrows` a matrix with boolean entries (i.e. `a` and `b` are both
`AbstractVector{Bool}` types) or to sort a list of sets (i.e. `a` and `b` are `Vector`s or
`Set`s)

"""
lessequal_GrRevLex(a::AbstractVector{Bool}, b::AbstractVector{Bool}) = a == b ? true : (sum(a) != sum(b) ? sum(a) < sum(b) : (a-b)[findlast(a-b)] < 0)
lessequal_GrRevLex(a, b) = a == b ? true : (length(a) != length(b) ? length(a) < length(b) : maximum(setdiff(a,b)) < maximum(setdiff(b,a)))

"""
    insert_sorted!(a::Vector{T}, item::T, lt)

Inserts `item` into sorted vector `a` in the appropriate position, according to the order
`lt`. Danger! Requires `item` to be of type `T`.

"""
insert_sorted!(a::Vector{T}, item::T, lt) where T = insert!(a, searchsortedlast(a, item, lt=lt), item)

# Tools for manipulating binary vectors as sets
"""
    binary_to_set(b, V)

Converts binary vector `b` into a subset of `V`, reresented as a vector.
"""
binary_to_set(b::AbstractVector{Bool}, V) = V[BitVector(b)]

"""
    set_to_binary(s, V)

Converts set `s` into a logical index to the (ordered) vertex set `V`

"""
function set_to_binary(s, V)
    b = falses(length(V))
    b[indexin(collect(s),collect(V))] = true
    return b
end

"""
    list_to_bitmatrix(L, V=collect(union(L...)))

Represents `L` as a binary matrix where the `i`th row is the logical index of
the `i`th list in `L` to the vertex set `V`. Does not attempt any pruning of
redundant faces; to get unique rows from the result `B`, use `unique(B, 1)`

"""
function list_to_bitmatrix(L, V=collect(union(L...)))
    B = falses(length(L), length(V))
    for (i, l) in enumerate(L)
        B[i, indexin(collect(l), V)] = true
    end
    return B
end

"""
    subset_rows(B)

Which rows in binary matrix `B` have support contained in the support of another row.
Returns a vector `V` with `V[i] = 0` if row `i` is not contained in any other row;
otherwise, `V[i] = j` means that set `i` is a subset of set `j`. If row `i` is contained in
multiple other rows, no guarantee about which will be returned.

"""
function subset_rows(B::AbstractMatrix{Bool})
    m,n = size(B)
    intersections = B * B'
    parent = zeros(Int,m)
    for i = 1:m
        if parent[i] == 0
            for j = (i+1):m
                if intersections[i,j] == intersections[i,i]
                    parent[i] = j
                    # found current set's parent
                elseif intersections[i,j] == intersections[j,j]
                    parent[j] = i
                    # current set is someone else's parent
                end
            end
        end
    end
    return parent
end
