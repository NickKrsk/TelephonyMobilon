
Функция SayName(Number)		
	Ответ = ВАТССервер.SayName(Number);
	Возврат Ответ;
КонецФункции

// Собитие, приходящее от ВАТС
Функция Event(Data)	
	ВАТССервер.Event(Data);
	Возврат 1;		
КонецФункции

Функция SayNameByINN(INN)
	Возврат ВАТССервер.SayNameByINN(INN);
КонецФункции


