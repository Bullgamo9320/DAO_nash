include("sample_games.jl")

############ Logger LEVEL設定（デフォルトはINFO） ############
#debuglogger = Logging.ConsoleLogger(stderr, Logging.Debug)
#Logging.global_logger(debuglogger)

############ サンプルゲームの実行 ############
#@time prisoners_dilemma1()
#@time prisoners_dilemma2()
@time prisoners_dilemma3()
#@time battle_of_sex()
#@time cournot_game1()
#@time cournot_game2()
#@time textbook_ex33a()
#@time hawk_dove_game()

