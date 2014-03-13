SELECT t, src, count(*) as out_degree
  
FROM [glnelson@washington.edu].[NF_PTC3_words_LD_E.csv]
GROUP BY t, src
ORDER BY t, src

SELECT t, snk, count(*) as in_degree
  
FROM [glnelson@washington.edu].[NF_PTC3_words_LD_E.csv]
GROUP BY t, snk
ORDER BY t, snk

SELECT *
FROM [glnelson@washington.edu].[gPTC3_V.csv] e
LEFT OUTER JOIN 
     [glnelson@washington.edu].ptc3_id_t_in i
  ON i.id = e.id
LEFT OUTER JOIN
     [glnelson@washington.edu].ptc3_id_t_out o
  on o.id = e.id
  WHERE 
  ((i.t is NULL or o.t is NULL) or (i.t is null and o.t is null)
  or i.t = o.t) 
