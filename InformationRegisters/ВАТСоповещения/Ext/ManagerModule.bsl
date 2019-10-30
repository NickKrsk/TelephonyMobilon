﻿Процедура ЗарегистрироватьОповещение(Данные) Экспорт
	
	Если Данные.direction = "incoming" И СтрДлина(Данные.from) < 7 
		ИЛИ Данные.direction = "external" И СтрДлина(Данные.to) < 7 
	Тогда	
		Возврат;
	КонецЕсли;
	
	
	Если ЗначениеЗаполнено(Данные.Пользователь) Тогда
		// Если показать некому, то такая запись не нужна
		МенеджерЗаписи = РегистрыСведений.ВАТСоповещения.СоздатьМенеджерЗаписи();
		МенеджерЗаписи.id = Новый УникальныйИдентификатор;
		МенеджерЗаписи.date	= ТекущаяДата();
		МенеджерЗаписи.numFrom = Данные.from;
		МенеджерЗаписи.user	= Данные.Пользователь;
		МенеджерЗаписи.state = Данные.state;
		МенеджерЗаписи.Записать();	
	КонецЕсли;	
	
КонецПроцедуры

Процедура ЗарегистрироватьОповещениеДокументТелефонныйЗвонок(Объект) Экспорт

	МенеджерЗаписи = РегистрыСведений.ВАТСоповещения.СоздатьМенеджерЗаписи();
	МенеджерЗаписи.id = Новый УникальныйИдентификатор;
	МенеджерЗаписи.date	= ТекущаяДата();
	МенеджерЗаписи.user	= Объект.Ответственный;
	МенеджерЗаписи.Объект = Объект;
	МенеджерЗаписи.Записать();	

КонецПроцедуры

