score_convert <- function(x){
  ifelse(x < 1,
         0,
         ifelse(x == 1, 1,
                ifelse(x == 2, 1.5,
                       ifelse(x == 3, 2,
                              ifelse(x == 4, 2.5,
                                     ifelse(x == 5, 3,
                                            ifelse(x == 6, 3.5,
                                                   ifelse(x == 7, 4,
                                                          ifelse(x == 8, 4.5,
                                                                 ifelse(x == 9, 5,
                                                                        ifelse(x == 10, 6,
                                                                               ifelse(x == 11, 6.5,
                                                                                      ifelse(x == 12, 7, 1)))))))))))))
}

reverse_score_convert <- function(x){
  ifelse(x < 1,
         0,
         ifelse(x == 1, 1,
                ifelse(x == 1.5, 2,
                       ifelse(x == 2, 3,
                              ifelse(x == 2.5, 4, 
                                     ifelse(x == 3, 5,
                                            ifelse(x == 3.5, 6,
                                                   ifelse(x == 4, 7, 
                                                          ifelse(x == 4.5, 8,
                                                                 ifelse(x == 5, 9, 
                                                                        ifelse(x == 6, 10,
                                                                               ifelse(x == 6.5, 11, 
                                                                                      ifelse(x == 7, 12, 
                                                                                             
                                                                                             ifelse(x == 5.5, 9, 1))))))))))))))
}