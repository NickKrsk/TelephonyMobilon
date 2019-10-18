﻿
Функция ПолучитьХМЛ(title, cateory_vip, phone_manager)	
	Стр = "<?xml version=""1.0""?>
	|<data>
  	|	<title>"+title+"</title>
  	|	<category>"+cateory_vip+"</category>
  	|	<manager>
    |		<phone>"+phone_manager+"</phone>
  	|	</manager>
	|</data>
	|";	
    Возврат Стр;	
КонецФункции

// Создание события при входящем или исходящем вызове.
// По состоянию "ANSWER" создаем Событие безусловно.
// По состоянию "HANGUP" проверяем было ли уже по данному "uuid" создано Событие. Если нет, то создаем.
Функция СоздатьСобытие(Данные)
	
	// Тут логика по созданию События	
	
КонецФункции

Функция ConvertUTMStringToStandard(UTMString)

	UTMStringStandard = UTMString;
	UTMStringStandard = СтрЗаменить(UTMStringStandard, "trm", "utm_term");
	UTMStringStandard = СтрЗаменить(UTMStringStandard, "cnt", "utm_content");
	UTMStringStandard = СтрЗаменить(UTMStringStandard, "cmp", "utm_campaign");
	UTMStringStandard = СтрЗаменить(UTMStringStandard, "mdm", "utm_medium");
	UTMStringStandard = СтрЗаменить(UTMStringStandard, "src", "utm_source");
	return UTMStringStandard;
	
КонецФункции // ConvertUTMStringToStandard()


Функция ПрочитатьДанные(Data)
	
	Чтение = Новый ЧтениеJSON;
	Чтение.УстановитьСтроку(Data);
	Данные = ПрочитатьJSON(Чтение, Ложь);
	Чтение.Закрыть();		
	Данные.Вставить("Пользователь");
	Данные.Вставить("Объект");
	Данные.Вставить("СНомера", Данные.from);
	Данные.Вставить("НаНомер", Данные.to);
	Данные.Вставить("ВнешнийНомер");
	
	Если НЕ Данные.Свойство("callstatus") Тогда
		// callstatus еще не приходил
		Данные.Вставить("callstatus");
	КонецЕсли;
	
	Если Данные.Свойство("utmString") Тогда
		Данные.utmString = ConvertUTMStringToStandard(Данные.utmString);		
	Иначе
		Данные.Вставить("utmString");
	КонецЕсли;
	
	Данные.Вставить("Документ");
	Возврат Данные;
	
КонецФункции // ПрочитатьДанные()

// Когда вызов пропущен, в событии HANGUP нет параметра callstatus, пример:
// {"from":"89831693504","to":"83912746614","baseid":"1565778980.25643","state":"HANGUP","direction":"incoming","uuid":"2ebc6689-b5da-4ddb-cd04-3eb81e9b14de","time":1565778995,"subid":"1565778980.25643","userkey":"5eeup9iodrzpt4ym","duration":"14"}
// В событии так же нет внутреннего номера, того, кто не принял вызов, есть только userkey, но от userkey мы уходим. 
// Поэтому понять, кому следует поставить напоминание о пропущенном можно так:
// Первый абонент, кто получил PREANSWER будет получать напоминания о пропущенном. 
// По одному звонку событий PREANSWER может быть несколько, если вызов поступает на группу или переводится по маршруту приема звонков. 
// Следовательно, нужно проверять события по параметру time и то событие, где time меньше всех, будет первым.
//
Функция ПолучитьПользователяДляПропущенногоЗвонка(uuid)
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	ВАТСЛогиЗапросов.to КАК to,
		|	МИНИМУМ(ВАТСЛогиЗапросов.time) КАК time
		|ИЗ
		|	РегистрСведений.ВАТСЛогиЗапросов КАК ВАТСЛогиЗапросов
		|ГДЕ
		|	ВАТСЛогиЗапросов.uuid = &uuid
		|	И ВАТСЛогиЗапросов.state = ""PREANSWER""
		|
		|СГРУППИРОВАТЬ ПО
		|	ВАТСЛогиЗапросов.to";
	
	Запрос.УстановитьПараметр("uuid", uuid);
	
	РезультатЗапроса = Запрос.Выполнить();	
	
	Если РезультатЗапроса.Пустой() Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	НаНомер = "";
	Выборка = РезультатЗапроса.Выбрать();	
	Пока Выборка.Следующий() Цикл
		НаНомер = Выборка.to;	
		Прервать;
	КонецЦикла;
	Возврат РегистрыСведений.ВАТСДополнительныеПараметрыПользователей.НайтиПользователя(НаНомер);	

КонецФункции // ПолучитьПользователяДляПропущенногоЗвонка()

Функция СоздатьДокументТелефонныйЗвонок(Данные)

	ТелефонныйЗвонок = Документы.ТелефонныйЗвонок.СоздатьДокумент();
	ТелефонныйЗвонок.Заполнить(Данные.Объект);	
	ТелефонныйЗвонок.Дата = ТекущаяДата();
	ТелефонныйЗвонок.Тема = "Мобилон, " + ?(Данные.direction = "external", "исходящий вызов: ", "входящий вызов: ") + Данные.ВнешнийНомер;
	ТелефонныйЗвонок.Описание = ТелефонныйЗвонок.Тема + ?(ЗначениеЗаполнено(Данные.utmString), Символы.ПС + Данные.utmString, "");
	ТелефонныйЗвонок.Входящий = ?(Данные.direction = "incoming", Истина, Ложь);
	ТелефонныйЗвонок.Ответственный = Данные.Пользователь;
	ТелефонныйЗвонок.Записать(РежимЗаписиДокумента.Запись);
	
	Взаимодействия.УстановитьПредмет(ТелефонныйЗвонок.Ссылка, ТелефонныйЗвонок.Ссылка);
	
	Возврат ТелефонныйЗвонок.Ссылка;
	
КонецФункции

Процедура СоздатьНапоминание(Данные)
	
	//НапоминанияПользователя.УстановитьНапоминание("Мобилон. Пропущенный вызов с номера " 
	//	+ Данные.from + ?(ЗначениеЗаполнено(Данные.Объект), " от " + Данные.Объект, ""), ТекущаяДата());

	Текст = "Мобилон. Пропущенный вызов с номера " + Данные.from + ?(ЗначениеЗаполнено(Данные.Объект), " от " + Данные.Объект, "");
	ПараметрыНапоминания = Новый Структура;
	ПараметрыНапоминания.Вставить("Описание", Текст);
	ПараметрыНапоминания.Вставить("ВремяСобытия", ТекущаяДата());
	ПараметрыНапоминания.Вставить("Пользователь", ПолучитьПользователяДляПропущенногоЗвонка(Данные.uuid));//Данные.Пользователь);
	ПараметрыНапоминания.Вставить("Источник", Данные.Документ);
	
	Попытка
		НапоминанияПользователяСлужебный.ПодключитьНапоминание(ПараметрыНапоминания);
	Исключение
		Сообщить(ОписаниеОшибки());
	КонецПопытки;		

КонецПроцедуры

Функция ПоПартнеруПолучитьКонтрагента(Партнер)

	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	Контрагенты.Ссылка КАК Контрагент
		|ИЗ
		|	Справочник.Контрагенты КАК Контрагенты
		|ГДЕ
		|	Контрагенты.Партнер = &Партнер";
	
	Запрос.УстановитьПараметр("Партнер", Партнер);
	
	РезультатЗапроса = Запрос.Выполнить();
	
	ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
	Пока ВыборкаДетальныеЗаписи.Следующий() Цикл
		Возврат ВыборкаДетальныеЗаписи.Контрагент;
	КонецЦикла;
	
	Возврат Неопределено;

КонецФункции // ПоПартнеруПолучитьКонтрагента()


#Область ПрограммныйИнтерфейс

Функция НайтиЗаписьВЖурналеЗвонков(ПолеУсловия, ЗначениеУсловия) Экспорт 

	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	ВАТСжурналЗвонков.uuid КАК uuid,
		|	ВАТСжурналЗвонков.ДатаЗвонка КАК ДатаЗвонка,
		|	ВАТСжурналЗвонков.СНомера КАК СНомера,
		|	ВАТСжурналЗвонков.НаНомер КАК НаНомер,
		|	ВАТСжурналЗвонков.callstatus КАК callstatus,
		|	ВАТСжурналЗвонков.Пользователь КАК Пользователь,
		|	ВАТСжурналЗвонков.direction КАК direction,
		|	ВАТСжурналЗвонков.recordUrl КАК recordUrl,
		|	ВАТСжурналЗвонков.state КАК state,
		|	ВАТСжурналЗвонков.time КАК time,
		|	ВАТСжурналЗвонков.duration КАК duration,
		|	ВАТСжурналЗвонков.userkey КАК userkey,
		|	ВАТСжурналЗвонков.Объект КАК Объект,
		|	ВАТСжурналЗвонков.Документ КАК Документ
		|ИЗ
		|	РегистрСведений.ВАТСжурналЗвонков КАК ВАТСжурналЗвонков
		|ГДЕ
		|	ВАТСжурналЗвонков.Документ = &ЗначениеУсловия";
	
	Запрос.Текст = СтрЗаменить(Запрос.Текст, "ВАТСжурналЗвонков.Документ = &ЗначениеУсловия", 
											"ВАТСжурналЗвонков." + ПолеУсловия + " = &ЗначениеУсловия");
	
	Запрос.УстановитьПараметр("ЗначениеУсловия", ЗначениеУсловия);	
	ВыборкаДетальныеЗаписи = Запрос.Выполнить().Выбрать();	
	Пока ВыборкаДетальныеЗаписи.Следующий() Цикл
		Возврат ВыборкаДетальныеЗаписи;	
	КонецЦикла;
	Возврат Неопределено;
	
КонецФункции // ПоСобытиюТелефонныйЗвонокПолучитьЗаписьЗвонка()


Функция ВернутьКонтрагентаПартнера(Партнер) Экспорт 

	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	Контрагенты.Ссылка КАК Контрагент
		|ИЗ
		|	Справочник.Контрагенты КАК Контрагенты
		|ГДЕ
		|	Контрагенты.Партнер = &Партнер";
	
	Запрос.УстановитьПараметр("Партнер", Партнер);
	
	РезультатЗапроса = Запрос.Выполнить();
	
	Выборка = РезультатЗапроса.Выбрать();
	Пока Выборка.Следующий() Цикл
		Возврат Выборка.Контрагент;	
	КонецЦикла;
	Возврат Неопределено;

КонецФункции // ВернутьКонтрагентаПартнера()

// SayNameByINN
// По ИНН возвращает наименование контрагента в формате:
// <?xml version="1.0"?>
//	<data>
//    <title>Гидравлика-Сервис</title>
//    <category>0</category>
//    <manager>
//        <phone>246</phone>
//    </manager>
//	</data>
//В случае, если с таким ИНН несколько контрагентов, то вернет последнего(с наибольшим кодом).
//
//В случае ошибки:
//<?xml version="1.0"?>
//<error>Не указан ИНН</error>
Функция SayNameByINN(INN) Экспорт
	Если НЕ ЗначениеЗаполнено(INN) Тогда
		Возврат "<?xml version=""1.0""?>
		|<error>Не указан ИНН</error>";
	КонецЕсли;
	
	Контрагент = Справочники.Контрагенты.НайтиКонтрагентаПоИНН(INN);
	Если ЗначениеЗаполнено(Контрагент) Тогда
		Возврат ПолучитьХМЛ(Контрагент.Наименование,Контрагент.КатегорияВИП,Контрагент.Куратор._ВнутреннийНомер);;	
	КонецЕсли;
	Ответ = "<?xml version=""1.0""?>
		|<error>Контрагент с ИНН "+INN+" не найден.</error>";
		Возврат Ответ;
КонецФункции

Функция GetNamesManegers() Экспорт
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	Контрагенты.Наименование,
		|	Контрагенты.НомерАккаунтаВАТС КАК НомерАккаунтаВАТС,
		|	Контрагенты.Куратор.Наименование,
		|	Контрагенты.КураторУдержания.Наименование
		|ИЗ
		|	Справочник.Контрагенты КАК Контрагенты
		|ГДЕ
		|	Контрагенты.НомерАккаунтаВАТС > 0
		|
		|УПОРЯДОЧИТЬ ПО
		|	НомерАккаунтаВАТС";
	
	РезультатЗапроса = Запрос.Выполнить();
	
	Стр = "<?xml version=""1.0""?>
	|<data>";
	Выборка = РезультатЗапроса.Выбрать();	
	Пока Выборка.Следующий() Цикл
		Стр=Стр+"
		|	<contragent>
		|		<title>"+Выборка.Наименование+"</title>
		|		<account_id>"+Выборка.НомерАккаунтаВАТС+"</account_id>
		|		<manager>
		|			<name>"+Выборка.КураторНаименование+"</name>
		|		</manager>
		|		<manager_second>
		|			<name>"+Выборка.КураторУдержанияНаименование+"</name>
		|		</manager_second>
		|	</contragent>";
	КонецЦикла;	
	Стр=Стр+"
	|</data>";
	
	Возврат Стр;
	
КонецФункции

Функция ПолучитьОповещенияПользователя() Экспорт
	
	Запрос = Новый Запрос;	
	Запрос.Текст = "ВЫБРАТЬ
	               |	ВАТСоповещения.user КАК user,
	               |	ВАТСоповещения.date КАК date,
	               |	ВАТСоповещения.numFrom КАК numFrom,
	               |	ВАТСоповещения.state КАК state,
	               |	ВАТСоповещения.id КАК id
	               |ИЗ
	               |	РегистрСведений.ВАТСоповещения КАК ВАТСоповещения
	               |ГДЕ
	               |	ВАТСоповещения.user = &Пользователь
	               |	И НЕ ВАТСоповещения.processed
	               |	И ВАТСоповещения.numFrom <> ""CallAPI""
	               |	И ВАТСоповещения.numFrom <> ""0000""";
	
	Запрос.УстановитьПараметр("Пользователь", ПараметрыСеанса.ТекущийПользователь);
	
	МассивДанных = Новый Массив;
	Запись = РегистрыСведений.ВАТСоповещения.СоздатьМенеджерЗаписи();
	Выборка = Запрос.Выполнить().Выбрать();	
	Пока Выборка.Следующий() Цикл	
		Если Выборка.date + 2*60 > ТекущаяДата() Тогда
			//Сообщение старше 2минут, оно уже неактуально
			Стр = Новый Структура("numFrom,state");
			ЗаполнитьЗначенияСвойств(Стр,Выборка);
			МассивДанных.Добавить(Стр);		
		КонецЕсли;				
		ЗаполнитьЗначенияСвойств(Запись,Выборка);
		Запись.Прочитать();
		Если Запись.Выбран() Тогда
			//Запись.processed = Истина;		
			//Запись.Записать();	
			Запись.Удалить();
		КонецЕсли;	
	КонецЦикла;	
	Возврат МассивДанных;
	
КонецФункции

Функция SayName(Number) Экспорт
	
	//РегистрыСведений.ВАТСЛогиЗапросов.ЗарегистрироватьСобытие(Number,"SayName"); Надо в JSON обернуть

	ПреобразованныйНомер = Формат(Number, "ЧГ=100");// В номере может придти число. При преобразовании в строку появятся пробелы: 2745000->2 745 000
	НаименованиеСотрудника = "";
	Партнер = НайтиОбъектПоНомеруТелефона(ПреобразованныйНомер).Партнер;
		
	Если ЗначениеЗаполнено(Партнер) Тогда
		Наименование		= НаименованиеСотрудника +" "+Партнер.Наименование;
		КатегорияВИП		= 0;
		ОсновнойМенеджер	= Партнер.ОсновнойМенеджер;
		ТелефонМенеджера	= РегистрыСведений.ВАТСДополнительныеПараметрыПользователей.ПолучитьЗначениеПараметра(ОсновнойМенеджер, "ВнутреннийНомер");
	Иначе
		Наименование		= "";
		КатегорияВИП		= "";
		ТелефонМенеджера	= "";
	КонецЕсли;		
	Возврат ПолучитьХМЛ(Наименование,КатегорияВИП,ТелефонМенеджера);
	
КонецФункции

// state - это состояние звонка. Значения: START, PREANSWER, IVR, ANSWER, HANGUP - описывают, что сейчас происходит со звонком
//
// callstatus - приходит при state = "HANGUP" и если звонок отвечен, то callstatus = ANSWER, в остальных случаях не приходит. 
// Показывает, был ли отвечен звонок.
//
// direction - направление. external - исходящий, incoming - входящий 
Процедура Event(Data) Экспорт
	
	РегистрыСведений.ВАТСЛогиЗапросов.ЗарегистрироватьСобытие(Data,"Event");
	
	Данные = ПрочитатьДанные(Data);	
	НомерПользователя = ?(Данные.direction = "external", Данные.from, Данные.to);
	Данные.ВнешнийНомер = ?(Данные.direction = "external", Данные.to, Данные.from); 
	Данные.Пользователь = РегистрыСведений.ВАТСДополнительныеПараметрыПользователей.НайтиПользователя(НомерПользователя);
	
	
	РезультатПоискаЗвонка = РегистрыСведений.ВАТСжурналЗвонков.НайтиЗвонокПоИдентификатору(Данные.uuid);	
	РегистрироватьЗвонок = Истина;
	МенеджерЗаписи				= РегистрыСведений.ВАТСжурналЗвонков.СоздатьМенеджерЗаписи();
	Если РезультатПоискаЗвонка = Неопределено Тогда
		// Такого звонка нет в базе, надо добавить					
		МенеджерЗаписи.ДатаЗвонка	= ТекущаяДата();
	Иначе
		// Звонок в базе есть, надо обновить			
		МенеджерЗаписи.uuid		= Данные.uuid;
		МенеджерЗаписи.Прочитать();
		
		//Если НЕ МенеджерЗаписи.Выбран() Тогда
		//	РегистрироватьЗвонок = Ложь;	
		//Иначе
		Данные.Объект = РезультатПоискаЗвонка.Объект;
		Данные.Документ = РезультатПоискаЗвонка.Документ;
		Если ЗначениеЗаполнено(РезультатПоискаЗвонка.callstatus) Тогда
			// Если отвечен, то так и указываем. 
			// Но в событии END callstatus не приходит, поэтому, чтобы не занулилось, заполняем 
			Данные.callstatus = РезультатПоискаЗвонка.callstatus;
		КонецЕсли;
		//КонецЕсли;	
	КонецЕсли;
	
	Если НЕ ЗначениеЗаполнено(Данные.Объект) Тогда                                 
		Данные.Объект = НайтиОбъектПоНомеруТелефона(Данные.ВнешнийНомер).Партнер;	
	КонецЕсли;
	
	Если Данные.state = "END" И НЕ ЗначениеЗаполнено(Данные.Документ) Тогда
		Данные.Документ = СоздатьДокументТелефонныйЗвонок(Данные);			
	КонецЕсли;
	
	Если РегистрироватьЗвонок Тогда		
		РегистрыСведений.ВАТСжурналЗвонков.ЗарегистрироватьИлиОбновитьЗвонок(МенеджерЗаписи, Данные);
	КонецЕсли;
			                                                    
	Если Данные.direction = "incoming" И Данные.state = "PREANSWER" Тогда//ИЛИ Данные.state = "ANSWER")
		РегистрыСведений.ВАТСоповещения.ЗарегистрироватьОповещение(Данные);
	КонецЕсли;
	
	// звонок неотвечен (пропущенный)
	Если Данные.direction = "incoming" И Данные.state = "END" И Данные.callstatus <> "ANSWER" Тогда		
		Попытка
			СоздатьНапоминание(Данные);
		Исключение
		КонецПопытки;
	КонецЕсли;
		
КонецПроцедуры

// Предполагаем, что по объекту не более одной записи
Функция ВернутьRecordUrl(Объект) Экспорт	
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	ВАТСЗвонкиПоОбъекту.recordUrl КАК recordUrl
		|ИЗ
		|	РегистрСведений.ВАТСЗвонкиПоОбъекту КАК ВАТСЗвонкиПоОбъекту
		|ГДЕ
		|	ВАТСЗвонкиПоОбъекту.Объект = &Объект
		|";
	
	Запрос.УстановитьПараметр("Объект", Объект);
	
	РезультатЗапроса = Запрос.Выполнить();	
	Выборка = РезультатЗапроса.Выбрать();
	Пока Выборка.Следующий() Цикл
		Возврат Выборка.recordUrl;
	КонецЦикла;
	Возврат Неопределено;	
	
КонецФункции

Функция ПолучитьЗначениеРеквизитаОбъекта(Объект, ИмяРеквизита) Экспорт
	Возврат Объект[ИмяРеквизита];
КонецФункции

Процедура Позвонить(number, Объект = Неопределено) Экспорт	
	
	УстановитьПривилегированныйРежим(Истина);
		
	password = Справочники.ВАТСКонстанты.ПолучитьЗначение("APIтокен");
	src_num = РегистрыСведений.ВАТСДополнительныеПараметрыПользователей.ПолучитьЗначениеПараметра(ВАТССервер.ВернутьТекущегоПользователя(), 
																											"ВнутреннийНомер");
	ssl		= Новый ЗащищенноеСоединениеOpenSSL( неопределено, неопределено );
	НТТР	= Новый HTTPСоединение("callapi.services.mobilon.ru",,,,,,ssl);
	//Запрос	= Новый HTTPЗапрос("/call/"+Константы.ВАТСТокенНоды.Получить()+":"+СокрЛП(key)+"/"+СокрЛП(number));
	Запрос	= Новый HTTPЗапрос("/simple-calls/call/?event=1&password=" + password + "&src_num=" + src_num + "&dst_num="+СокрЛП(number));
	Ответ	= НТТР.Получить(Запрос);
	
	Если Ответ.КодСостояния <> 200 Тогда
		ТекстСообщения = "Не удалось совершить исходящий вызов. Возможно, проблема на ВАТС.";
		Сообщить(ТекстСообщения);
		ВызватьИсключение ТекстСообщения;
	КонецЕсли;
	
	//Чтение = Новый ЧтениеJSON;
	//Чтение.УстановитьСтроку(Ответ.ПолучитьТелоКакСтроку());
	//Данные = ПрочитатьJSON(Чтение, Ложь);
	//Чтение.Закрыть();
	//
	//РегистрыСведений.ВАТСжурналЗвонков.ЗарегистрироватьИсходящийЗвонок(ПараметрыСеанса.ТекущийПользователь, Объект, number, 																	Данные.uuid, Данные.recordUrl);		
	
	УстановитьПривилегированныйРежим(Ложь); 
	
 КонецПроцедуры

Функция ВернутьТекущегоПользователя() Экспорт 

	Возврат ПараметрыСеанса.ТекущийПользователь;

КонецФункции // ВернутьТекущегоПользователя()

Функция ПолучитьСписокНомеровКонтрагента(Партнер) Экспорт 
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	КонтрагентыКонтактнаяИнформация.НомерТелефона КАК НомерТелефона,
	|	КонтрагентыКонтактнаяИнформация.Ссылка.Наименование КАК Представление,
	|	КонтрагентыКонтактнаяИнформация.Ссылка.Партнер КАК Партнер
	|ИЗ
	|	Справочник.Контрагенты.КонтактнаяИнформация КАК КонтрагентыКонтактнаяИнформация
	|ГДЕ
	|	КонтрагентыКонтактнаяИнформация.Ссылка.Партнер = &Партнер
	|
	|ОБЪЕДИНИТЬ ВСЕ
	|
	|ВЫБРАТЬ
	|	КонтактныеЛицаПартнеров.НомерТелефона,
	|	КонтактныеЛицаПартнеров.Ссылка.Наименование,
	|	КонтактныеЛицаПартнеров.Ссылка
	|ИЗ
	|	Справочник.КонтактныеЛицаПартнеров.КонтактнаяИнформация КАК КонтактныеЛицаПартнеров
	|ГДЕ
	|	КонтактныеЛицаПартнеров.Ссылка.Владелец = &Партнер
	|
	|ОБЪЕДИНИТЬ ВСЕ
	|
	|ВЫБРАТЬ
	|	ПартнерыКонтактнаяИнформация.Представление,
	|	ПартнерыКонтактнаяИнформация.Ссылка.Наименование,
	|	ПартнерыКонтактнаяИнформация.Ссылка
	|ИЗ
	|	Справочник.Партнеры.КонтактнаяИнформация КАК ПартнерыКонтактнаяИнформация
	|ГДЕ
	|	ПартнерыКонтактнаяИнформация.Ссылка = &Партнер
	|	И ПартнерыКонтактнаяИнформация.Вид = ЗНАЧЕНИЕ(Справочник.ВидыКонтактнойИнформации.ТелефонПартнера)";
	
	//Запрос.УстановитьПараметр("Ссылка", Контрагент);
	//Запрос.УстановитьПараметр("Партнер", Контрагент.Партнер);
	Запрос.УстановитьПараметр("Партнер", Партнер);
	
	ТЗ = Новый ТаблицаЗначений;
	ТЗ.Колонки.Добавить("Номер");
	ТЗ.Колонки.Добавить("КонтактноеЛицо",,"Контактное лицо");
	
	СЗ	= Новый СписокЗначений;
	
	Результат	= Запрос.Выполнить();	
	Выборка		= Результат.Выбрать();
	Пока Выборка.Следующий() Цикл
		мас			= Новый Массив;

		Номер = Выборка.НомерТелефона;		
		Номер = СтрЗаменить(Номер,"-","");
		Номер = СтрЗаменить(Номер,"(","");
		Номер = СтрЗаменить(Номер,"(","");
		Номер = СтрЗаменить(Номер,")","");

		Если СтрДлина(Номер) = 10 Тогда//Если (Лев(Номер,1)<>"8" ИЛИ Лев(Номер,3)="812") И СтрДлина(Номер)>7 Тогда// 812 - код Питера
			Номер = "8" + Номер;
		ИначеЕсли Не ЗначениеЗаполнено(Номер) Тогда
			Продолжить;
		КонецЕсли;
		
		мас.Добавить(Номер);
		мас.Добавить(Выборка.Партнер);
		СЗ.Добавить(мас, Строка(Номер)+" ("+Выборка.Представление+")");
		
		новСтр					= ТЗ.Добавить();
		новСтр.Номер			= Номер;
		новСтр.КонтактноеЛицо	= Выборка.Представление;		
	КонецЦикла;	
	Возврат СЗ;

КонецФункции

Функция НайтиОбъектПоНомеруТелефона(Номер) Экспорт 
	
	Результат = Новый Структура("Контрагент, Партнер, КонтактноеЛицо");

	Если СтрДлина(Номер)< 6 Тогда
		Возврат Результат;
	КонецЕсли;
	
	// поиск по контрагентам
	Запрос = Новый Запрос;
	Запрос.Текст = "ВЫБРАТЬ
               |	ПартнерыКонтактнаяИнформация.Представление КАК НомерТелефона,
               |	ПартнерыКонтактнаяИнформация.Ссылка.Представление КАК Представление,
               |	NULL КАК Контрагент,
               |	NULL КАК КонтактноеЛицо,
               |	ПартнерыКонтактнаяИнформация.Ссылка КАК Партнер
               |ИЗ
               |	Справочник.Партнеры.КонтактнаяИнформация КАК ПартнерыКонтактнаяИнформация
               |ГДЕ
               |	ПартнерыКонтактнаяИнформация.Представление ПОДОБНО &Номер
               |
               |ОБЪЕДИНИТЬ ВСЕ
               |
               |ВЫБРАТЬ
               |	КонтактныеЛицаПартнеров.НомерТелефона,
               |	КонтактныеЛицаПартнеров.Ссылка.Наименование,
               |	NULL,
               |	КонтактныеЛицаПартнеров.Ссылка.Представление,
               |	КонтактныеЛицаПартнеров.Ссылка.Владелец
               |ИЗ
               |	Справочник.КонтактныеЛицаПартнеров.КонтактнаяИнформация КАК КонтактныеЛицаПартнеров
               |ГДЕ
               |	КонтактныеЛицаПартнеров.НомерТелефона ПОДОБНО &Номер
               |
               |ОБЪЕДИНИТЬ ВСЕ
               |
               |ВЫБРАТЬ
               |	КонтрагентыКонтактнаяИнформация.НомерТелефона,
               |	КонтрагентыКонтактнаяИнформация.Ссылка.Наименование,
               |	КонтрагентыКонтактнаяИнформация.Ссылка,
               |	"""",
               |	КонтрагентыКонтактнаяИнформация.Ссылка.Партнер
               |ИЗ
               |	Справочник.Контрагенты.КонтактнаяИнформация КАК КонтрагентыКонтактнаяИнформация
               |ГДЕ
               |	КонтрагентыКонтактнаяИнформация.НомерТелефона ПОДОБНО &Номер";

	Запрос.УстановитьПараметр("Номер", "%"+Сред(Номер,2)+"%");	
	Выборка = Запрос.Выполнить().Выбрать();
	Пока Выборка.Следующий() Цикл
		ЗаполнитьЗначенияСвойств(Результат, Выборка);
		Возврат Результат;//Выборка.Контрагент;
	КонецЦикла;
	Возврат Результат;
	
КонецФункции

Функция ПолучитьЗначениеПараметра(Пользователь, НаваниеПараметра) Экспорт 

	Возврат РегистрыСведений.ВАТСДополнительныеПараметрыПользователей.ПолучитьЗначениеПараметра(Пользователь, НаваниеПараметра);	

КонецФункции // ()

Функция СоздатьЗаказКлиентаНаОснованииТелефонногоЗвонка(ТелефонныйЗвонок) Экспорт 

	Заказ = Документы.ЗаказКлиента.СоздатьДокумент();
	Заказ.Заполнить(Неопределено);
	Заказ.Партнер = ТелефонныйЗвонок.АбонентКонтакт;
	Заказ.Контрагент = ПоПартнеруПолучитьКонтрагента(Заказ.Партнер);
	Заказ.Дата = ТекущаяДата();
	Заказ.Комментарий = ТелефонныйЗвонок.Комментарий + Символы.ПС + ТелефонныйЗвонок.Описание;
	Заказ.Записать(РежимЗаписиДокумента.Запись);
	Возврат Заказ.Ссылка;

КонецФункции // СоздатьЗаказКлиентаНаОснованииТелефонногоЗвонка()


#КонецОбласти


