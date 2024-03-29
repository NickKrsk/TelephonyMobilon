﻿
Процедура ПоказатьФормуВходящегоЗвонка() Экспорт
	
	
	ТекущийПользователь = ВАТССервер.ВернутьТекущегоПользователя();
	ПоказыватьРасширеннуюИнформациюПриЗвонках = ВАТССервер.ПолучитьЗначениеПараметра(ТекущийПользователь, "ПоказыватьРасширеннуюИнформациюПриЗвонках"); 
	Оповещения = ВАТССервер.ПолучитьОповещенияПользователя();
	
	Для каждого текЭл Из Оповещения Цикл	
		Если ЗначениеЗаполнено(текЭл.Объект) Тогда
			ОткрытьЗначение(текЭл.Объект);	
			Продолжить;
		КонецЕсли;
		
				
		ФормаЗвонка = ПолучитьФорму("Обработка.ВходящийЗвонок.Форма.Форма", , ,Новый УникальныйИдентификатор());
		ДанныеФормы = ФормаЗвонка.Объект; 
		ДанныеФормы.СНомера = текЭл.numFrom;
		ДанныеФормы.Источник = ВернутьМеткуИсточник(текЭл.utmString);
		ФормаЗвонка.Открыть();	
		Если НЕ ПоказыватьРасширеннуюИнформациюПриЗвонках Тогда
			Попытка
				ФормаЗвонка.Закрыть();
			Исключение
			КонецПопытки;	
		КонецЕсли;	
	КонецЦикла;	
	
КонецПроцедуры

Функция ВернутьМеткуИсточник(utmString)

	массивМеток = ВАТССервер.ИзСтрокиСРазделителями(utmString, ";");
	Для каждого  Эл Из массивМеток Цикл
		Если СтрНайти(Эл, "utm_source") > 0 Тогда
			Возврат Эл;			
		КонецЕсли;		
	КонецЦикла;
	Возврат "";

КонецФункции // ()

