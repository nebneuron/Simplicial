###################### This is the type that defines combinatorial codes
type CombinatorialCode
  words::Array{CodeWord,1}   # the codewords, these are ordered by the weights (in the increasing order)
  weights::Array{Int,1} # the sizes of the codewords in the same order as the words
  MaximumWeight::Int  #
  Minimumweight::Int  #
  Nwords::Int       	# total number of codewords in the code
  vertices::CodeWord 	# the set of all vertices that show up in the code
  ## this is the constructor for the CombinatorialCode type. It takes a list of Integer arrays, where each array represents a codeword
  ## codewords are checked for duplication

  # The following function constructs a combinatorial code from a list of words
  function CombinatorialCode(ListOfWords::Vector)
    if length(ListOfWords)<1; println("WARNING: The void code was passed!!");
      return new([], Array{Int,1}([]),-1,-1,0,emptyset)
    end
    vertices=emptyset # keep track of all the vertices here
    # First, compute the weights
    weights=zeros(Int,length(ListOfWords))
    for i=1:length(ListOfWords)
    weights[i]=length(unique(ListOfWords[i]))
    end
    MaximumWeight=maximum(weights)
    Minimumweight=minimum(weights)
    # next we figure out if there are any duplicate words in the list and populate the list of sets named words
    words=CodeWord[];
    ThereWereDuplicates=false
    for w= Minimumweight:MaximumWeight
      Ind=find(weights.==w);
      L=length(Ind);
      if L>0
        CurrentListOfWords=CodeWord[];
        # if there was more than one word with the same weights we check the repeated words
        for j=1:L
          CurrentSet=CodeWord((ListOfWords[Ind[j]]))
          CurrentSetIsDuplicated=false
          for k=1:length(CurrentListOfWords) # check the previous words of the same weight is duplicated, if yes, then discard the CurrentSet
          	if CurrentListOfWords[k]==CurrentSet
              CurrentSetIsDuplicated=true
              ThereWereDuplicates=true
          		break
          	end
          end
          if ~CurrentSetIsDuplicated
          push!(CurrentListOfWords,CurrentSet)
          push!(words,CurrentSet)
          vertices=union(vertices,CurrentSet)
          end
        end
      end
    end
    Nwords=length(words)
    # now we recompute the weights for possibly reduced list, since we removed all the duplicates
    weights=zeros(Int,Nwords)
    for i=1:Nwords ; weights[i]=length(words[i]); end
    if ThereWereDuplicates println("Warning: There were duplicated words") end
    new(words,weights,MaximumWeight,Minimumweight,Nwords,vertices)
  end


"""
   CombinatorialCode(words::Array{CodeWord,1}, vertices::CodeWord)
   This function is a "brute-force constructor" of a code (added as a convinience)
"""
  function CombinatorialCode(words::Array{CodeWord,1}, vertices::CodeWord)
    Nwords=length(words);
    if Nwords==0; return CombinatorialCode([]); end
    weights=zeros(Int,Nwords);  for i=1:Nwords; weights[i]=length(words[i]) end
    MaximumWeight=maximum(weights) ;   Minimumweight=minimum(weights);
    # perform one sanity check: ensure that  the union of all words is contained in the set of vertices
    collected_vertices=emptyset # keep track of all the vertices here
    for aword=words; collected_vertices=union(collected_vertices,aword); end
    if !issubset(collected_vertices,vertices); error(" the union of vertices in the words should be a subset of the vertices field"); end
    new(words,weights,MaximumWeight,Minimumweight,Nwords,vertices)
  end

end

###############################################################################################

#################
# ITERATION
#################
function start(CC::CombinatorialCode)
  return 1
end
function next(CC::CombinatorialCode, state)
  return (CC.words[state], state+1)
end
function done(CC::CombinatorialCode, state)
  return state > length(CC.words)
end
function eltype(::CombinatorialCode)
  return CodeWord
end
function eltype(::Type{CombinatorialCode})
  return CodeWord
end
function length(CC::CombinatorialCode)
  return length(CC.words)
end



# This is a function that detects if the code has the empty set:
HasEmptySet(code::CombinatorialCode)=in(emptyset,code)





# Below are types and methods associated to the BitArray representation of codes
# This representation is (inconviniently) used by some methods, such as CanonicalForm

" BitArrayOfACombinatorialCode is a different representation of a CombinatorialCode"
type BitArrayOfACombinatorialCode
     BinaryMatrix::BitArray{2}  # This is a binary representation of the code
                                # The rows correspond to the vertices
                                # The columns correspond to the codewords
     VertexTranslation::Array{Int,1}
end

"""
    BitArrayOfACombinatorialCode(C::CombinatorialCode)::BitArrayOfACombinatorialCode
    This function converts the CombinatorialCode representation to the BitArrayOfACombinatorialCode representation

"""
function BitArrayOfACombinatorialCode(C::CombinatorialCode)::BitArrayOfACombinatorialCode
         Nvertices=length(C.vertices); Nwords=length(C.words);
         OrderedListOfVertexNumbers=sort(collect(C.vertices))

         # We also need to construct a dictionary that translates
         # an  integer vertex label into the appropriate position in  OrderedListOfVertexNumbers
         LookUp=Dict{TheIntegerType,Int}(); for i=1: Nvertices; LookUp[OrderedListOfVertexNumbers[i]]=i;end

         # First, we initiate the binary mtx with all zeros
         B=BitArrayOfACombinatorialCode(falses(Nwords,Nvertices), OrderedListOfVertexNumbers);
         # now we go through the list of codewords and assign each column
         for j=1: Nwords
             the_word = collect(C.words[j]);
             L = length(the_word) ; the_substitution = Array{Int}(L);
             for p=1:L
                 the_substitution[p]=LookUp[the_word[p]]
             end
         B.BinaryMatrix[j,the_substitution]=true
         end
        return B
end

"""
CombinatorialCode(BinaryMatrix::BitArray{2})::CombinatorialCode
This function takes a binary matrix and interprets it as a combinatorial code, so that each row is interpreted as a codeword.
"""
function CombinatorialCode(BinaryMatrix::BitArray{2})::CombinatorialCode
  # So far we ignore the field B.VertexTranslation
Nwords,Nvertices=size(BinaryMatrix);
if Nwords==0
   return CombinatorialCode([])
else
  ListOfWords=Array{CodeWord,1}(Nwords);
  for i=1: Nwords; ListOfWords[i]=CodeWord(find(BinaryMatrix[i,:])); end
  sort!(ListOfWords,by=length)
return  CombinatorialCode(ListOfWords,CodeWord(collect(1:Nvertices)))
end
end


"""
This function takes a combinatorial code and computes `the transpose of a code`
Usage: C1=transpose(C)
or, (same result)
       C1=C'
"""

function transpose(CC::CombinatorialCode)::CombinatorialCode
          BA=BitArrayOfACombinatorialCode(CC);
          return CombinatorialCode(BA.BinaryMatrix')
end
