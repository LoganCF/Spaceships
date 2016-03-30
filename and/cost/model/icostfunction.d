module and.cost.model.icostfunction;

/** Interface for computing the 'cost' or 'error' of the network */
interface ICostFunction
{
  /** Parameters: expected ( outputs ), actual ( outputs ) */
  real f(real [] expected , real [] actual );

}

/** Base CostFunction class with default errorThreshold and constructor */
class CostFunction : ICostFunction
{
  
  abstract real f(real [] expected , real [] actual ); /// Compute the cost for the network

}

