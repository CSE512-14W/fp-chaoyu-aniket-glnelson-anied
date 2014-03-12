SELECT t, src, count(*) as out_degree
  
FROM [glnelson@washington.edu].[NF_PTC3_words_LD_E.csv]
GROUP BY t, src
ORDER BY t, src

SELECT t, snk, count(*) as in_degree
  
FROM [glnelson@washington.edu].[NF_PTC3_words_LD_E.csv]
GROUP BY t, snk
ORDER BY t, snk
