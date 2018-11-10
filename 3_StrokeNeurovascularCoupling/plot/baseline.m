function week = baseline(currentWeek,BaseWeek)

if BaseWeek
    week = 1;
else
    week = currentWeek-1;
end
end