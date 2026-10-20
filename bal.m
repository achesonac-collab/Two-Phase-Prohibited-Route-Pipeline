   total_supply = sum(supply);
    total_demand = sum(demand);
    dummy_source = false;
dummy_dest = false;
if total_supply > total_demand
    d = d + 1;
    demand(end+1) = total_supply - total_demand;
    dummy_dest = true;
    fprintf('\nAdded dummy destination D%d with demand = %.2f.\n', d, demand(end));
elseif total_demand > total_supply
    s = s + 1;
    supply(end+1) = total_demand - total_supply;
    dummy_source = true;
    fprintf('\nAdded dummy source S%d with supply = %.2f.\n', s, supply(end));
end