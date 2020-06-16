export AbstractFlixUIError

abstract type AbstractFlixUIError <: Exception end

@makesimpleerror FontError AbstractFlixUIError "Font error"
