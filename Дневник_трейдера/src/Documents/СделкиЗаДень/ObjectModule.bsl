
#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область ОбработчикиСобытий

Процедура ПередЗаписью(Отказ, РежимЗаписи, РежимПроведения)
	ТаблицаСделки = Сделки.Выгрузить();
	ТаблицаСделки.Сортировать("ДатаВремяСделки");
	Сделки.Загрузить(ТаблицаСделки);
КонецПроцедуры

Процедура ОбработкаПроведения(Отказ, Режим)

	ЗапросОстаткиЦенныхБумаг = Новый Запрос(
	"ВЫБРАТЬ
	|	ОстаткиЦенныхБумагОстатки.ЦеннаяБумага КАК ЦеннаяБумага,
	|	ОстаткиЦенныхБумагОстатки.Валюта КАК Валюта,
	|	ОстаткиЦенныхБумагОстатки.Цена КАК Цена,
	|	ОстаткиЦенныхБумагОстатки.ДатаПокупки КАК ДатаПокупки,
	|	ОстаткиЦенныхБумагОстатки.КоличествоОстаток КАК КоличествоОстаток,
	|	ОстаткиЦенныхБумагОстатки.СуммаОстаток КАК СуммаОстаток
	|ИЗ
	|	РегистрНакопления.ОстаткиЦенныхБумаг.Остатки(
	|			&НачалоДня,
	|			БрокерскийСчет = &БрокерскийСчет
	|				И ЦеннаяБумага В (&МассивЦенныхБумаг)) КАК ОстаткиЦенныхБумагОстатки
	|
	|УПОРЯДОЧИТЬ ПО
	|	ЦеннаяБумага,
	|	ДатаПокупки");
	
	ЗапросОстаткиЦенныхБумаг.УстановитьПараметр("НачалоДня", НачалоДня(Дата) + 6 * 3600); // остатки берутся на 6 утра
	ЗапросОстаткиЦенныхБумаг.УстановитьПараметр("БрокерскийСчет", БрокерскийСчет);
	ЗапросОстаткиЦенныхБумаг.УстановитьПараметр("МассивЦенныхБумаг", Сделки.ВыгрузитьКолонку("ЦеннаяБумага"));
	
	ОстаткиЦенныхБумаг = ЗапросОстаткиЦенныхБумаг.Выполнить().Выгрузить();
	
	Движения.ОстаткиЦенныхБумаг.Записывать = Истина;
	Движения.ОстаткиДенежныхСредств.Записывать = Истина;
	Для Каждого ТекСтрокаСделкиЗаДень Из Сделки Цикл
		
		Если ТекСтрокаСделкиЗаДень.ТипСделки = Перечисления.ТипыСделок.Покупка Тогда
			
			ТекОстаток = ТекСтрокаСделкиЗаДень.Количество;
			
			СтрокиОстатковПоЦБ = ОстаткиЦенныхБумаг.НайтиСтроки(Новый Структура("ЦеннаяБумага, Валюта", ТекСтрокаСделкиЗаДень.ЦеннаяБумага, ТекСтрокаСделкиЗаДень.Валюта));
			
			Для Каждого СтрОстаток Из СтрокиОстатковПоЦБ Цикл
				
				Если СтрОстаток.КоличествоОстаток >= 0 Тогда
					Продолжить;
				КонецЕсли;
				Если СтрОстаток.ДатаПокупки >= ТекСтрокаСделкиЗаДень.ДатаВремяСделки Тогда
					Продолжить;
				КонецЕсли;
				Если ТекОстаток <= 0 Тогда
					Прервать;
				КонецЕсли;
				КПоступлению = Мин(ТекОстаток, -СтрОстаток.КоличествоОстаток);
				СуммаКПоступлению = ?(-СтрОстаток.КоличествоОстаток = КПоступлению, -СтрОстаток.СуммаОстаток, СтрОстаток.СуммаОстаток * КПоступлению / СтрОстаток.КоличествоОстаток);

				Движение = Движения.ОстаткиЦенныхБумаг.Добавить();
				Движение.Период = ?(ЗначениеЗаполнено(ТекСтрокаСделкиЗаДень.ДатаВремяСделки), ТекСтрокаСделкиЗаДень.ДатаВремяСделки, Дата);
				Движение.БрокерскийСчет = БрокерскийСчет;
				Движение.Валюта = ТекСтрокаСделкиЗаДень.Валюта;
				Движение.ЦеннаяБумага = ТекСтрокаСделкиЗаДень.ЦеннаяБумага;
				Движение.ВидДвижения = ВидДвиженияНакопления.Приход;
				Движение.Цена = СтрОстаток.Цена;
				Движение.ДатаПокупки = СтрОстаток.ДатаПокупки;
				Движение.Количество = КПоступлению;
				Движение.Сумма = СуммаКПоступлению;
				
				ТекОстаток = ТекОстаток - КПоступлению;
				СтрОстаток.КоличествоОстаток = СтрОстаток.КоличествоОстаток + КПоступлению;
				СтрОстаток.СуммаОстаток = СтрОстаток.СуммаОстаток - СуммаКПоступлению;
				
			КонецЦикла;	
			
			Если ТекОстаток <> 0 Тогда
				
				Движение = Движения.ОстаткиЦенныхБумаг.Добавить();
				Движение.Период = ?(ЗначениеЗаполнено(ТекСтрокаСделкиЗаДень.ДатаВремяСделки), ТекСтрокаСделкиЗаДень.ДатаВремяСделки, Дата);
				Движение.БрокерскийСчет = БрокерскийСчет;
				Движение.Валюта = ТекСтрокаСделкиЗаДень.Валюта;
				Движение.ЦеннаяБумага = ТекСтрокаСделкиЗаДень.ЦеннаяБумага;
				Движение.ВидДвижения = ВидДвиженияНакопления.Приход;
				Движение.Количество = ТекОстаток;
				Движение.Цена = ТекСтрокаСделкиЗаДень.Цена;
				Движение.ДатаПокупки = ТекСтрокаСделкиЗаДень.ДатаВремяСделки;
				Движение.Сумма = ?(ТекОстаток = ТекСтрокаСделкиЗаДень.Количество, ТекСтрокаСделкиЗаДень.Сумма, ТекОстаток * ТекСтрокаСделкиЗаДень.Цена);
				
				СтрОстаткиЦенныхБумаг = ОстаткиЦенныхБумаг.Добавить();
				ЗаполнитьЗначенияСвойств(СтрОстаткиЦенныхБумаг, ТекСтрокаСделкиЗаДень);
				СтрОстаткиЦенныхБумаг.ДатаПокупки = ТекСтрокаСделкиЗаДень.ДатаВремяСделки;
				СтрОстаткиЦенныхБумаг.КоличествоОстаток = ТекСтрокаСделкиЗаДень.Количество;
				СтрОстаткиЦенныхБумаг.СуммаОстаток = ТекСтрокаСделкиЗаДень.Сумма;
			
			КонецЕсли;
			
		ИначеЕсли ТекСтрокаСделкиЗаДень.ТипСделки = Перечисления.ТипыСделок.Продажа Тогда
			
			ТекОстаток = ТекСтрокаСделкиЗаДень.Количество;
			
			СтрокиОстатковПоЦБ = ОстаткиЦенныхБумаг.НайтиСтроки(Новый Структура("ЦеннаяБумага, Валюта", ТекСтрокаСделкиЗаДень.ЦеннаяБумага, ТекСтрокаСделкиЗаДень.Валюта));
			
			Для Каждого СтрОстаток Из СтрокиОстатковПоЦБ Цикл
				
				Если СтрОстаток.КоличествоОстаток <= 0 Тогда
					Продолжить;
				КонецЕсли;
				Если СтрОстаток.ДатаПокупки >= ТекСтрокаСделкиЗаДень.ДатаВремяСделки Тогда
					Продолжить;
				КонецЕсли;
				Если ТекОстаток <= 0 Тогда
					Прервать;
				КонецЕсли;
				КСписанию = Мин(ТекОстаток, СтрОстаток.КоличествоОстаток);
				СуммаКСписанию = ?(СтрОстаток.КоличествоОстаток = КСписанию, СтрОстаток.СуммаОстаток, СтрОстаток.СуммаОстаток * КСписанию / СтрОстаток.КоличествоОстаток);

				Движение = Движения.ОстаткиЦенныхБумаг.Добавить();
				Движение.Период = ?(ЗначениеЗаполнено(ТекСтрокаСделкиЗаДень.ДатаВремяСделки), ТекСтрокаСделкиЗаДень.ДатаВремяСделки, Дата);
				Движение.БрокерскийСчет = БрокерскийСчет;
				Движение.Валюта = ТекСтрокаСделкиЗаДень.Валюта;
				Движение.ЦеннаяБумага = ТекСтрокаСделкиЗаДень.ЦеннаяБумага;
				Движение.ВидДвижения = ВидДвиженияНакопления.Расход;
				Движение.Цена = СтрОстаток.Цена;
				Движение.ДатаПокупки = СтрОстаток.ДатаПокупки;
				Движение.Количество = КСписанию;
				Движение.Сумма = СуммаКСписанию;
				
				ТекОстаток = ТекОстаток - КСписанию;
				СтрОстаток.КоличествоОстаток = СтрОстаток.КоличествоОстаток - КСписанию;
				СтрОстаток.СуммаОстаток = СтрОстаток.СуммаОстаток - СуммаКСписанию;
				
			КонецЦикла;	
			
			Если ТекОстаток <> 0 Тогда
				
				Движение = Движения.ОстаткиЦенныхБумаг.Добавить();
				Движение.Период = ?(ЗначениеЗаполнено(ТекСтрокаСделкиЗаДень.ДатаВремяСделки), ТекСтрокаСделкиЗаДень.ДатаВремяСделки, Дата);
				Движение.БрокерскийСчет = БрокерскийСчет;
				Движение.Валюта = ТекСтрокаСделкиЗаДень.Валюта;
				Движение.ЦеннаяБумага = ТекСтрокаСделкиЗаДень.ЦеннаяБумага;
				Движение.ВидДвижения = ВидДвиженияНакопления.Расход;
				Движение.Количество = ТекОстаток;
				Движение.Цена = ТекСтрокаСделкиЗаДень.Цена;
				Движение.ДатаПокупки = ТекСтрокаСделкиЗаДень.ДатаВремяСделки;
				Движение.Сумма = ТекОстаток * ТекСтрокаСделкиЗаДень.Цена;
				
				СтрОстаткиЦенныхБумаг = ОстаткиЦенныхБумаг.Добавить();
				ЗаполнитьЗначенияСвойств(СтрОстаткиЦенныхБумаг, ТекСтрокаСделкиЗаДень);
				СтрОстаткиЦенныхБумаг.ДатаПокупки = ТекСтрокаСделкиЗаДень.ДатаВремяСделки;
				СтрОстаткиЦенныхБумаг.КоличествоОстаток = -ТекСтрокаСделкиЗаДень.Количество;
				СтрОстаткиЦенныхБумаг.СуммаОстаток = -ТекСтрокаСделкиЗаДень.Сумма;
			
			КонецЕсли;
			
		КонецЕсли;
		
		ВалютаОбмена = Справочники.Валюты.ПустаяСсылка();
		Если ТекСтрокаСделкиЗаДень.ЦеннаяБумага.ТипИнструмента = Перечисления.ТипыИнструментов.Валюта Тогда
			Тикер = ТекСтрокаСделкиЗаДень.ЦеннаяБумага.Наименование;
			Если Тикер = "USDRUB" Тогда
				ВалютаОбмена = Справочники.Валюты.НайтиПоНаименованию("USD");
			ИначеЕсли Тикер = "EURRUB" Тогда	 
				ВалютаОбмена = Справочники.Валюты.НайтиПоНаименованию("EUR");
			Иначе	 
				ВалютаОбмена = Справочники.Валюты.НайтиПоНаименованию(Лев(Тикер, 3));
			КонецЕсли;	
		КонецЕсли;	
		
		Если ТекСтрокаСделкиЗаДень.ТипСделки = Перечисления.ТипыСделок.Покупка Тогда
			Движение = Движения.ОстаткиДенежныхСредств.Добавить();
			Движение.ВидДвижения = ВидДвиженияНакопления.Расход;
			Движение.Период = ТекСтрокаСделкиЗаДень.ДатаВремяСделки;
			Движение.БрокерскийСчет = БрокерскийСчет;
			Движение.Валюта = ТекСтрокаСделкиЗаДень.Валюта;
			Движение.Сумма = ТекСтрокаСделкиЗаДень.Сумма;
			Движение.ПричинаИзменения = Перечисления.ПричиныИзмененияОстатковДенежныхСредств.ПокупкаЦеннойБумаги;
			Если Не ВалютаОбмена.Пустая() Тогда
				Движение.ПричинаИзменения = Перечисления.ПричиныИзмененияОстатковДенежныхСредств.ОбменВалютыСписание;
				ПричинаИзмененияОбратная = Перечисления.ПричиныИзмененияОстатковДенежныхСредств.ОбменВалютыПоступление;
				КоличествоВалюты = ТекСтрокаСделкиЗаДень.Количество;
				ВидДвиженияОбратный = ВидДвиженияНакопления.Приход;
			КонецЕсли;			
		ИначеЕсли ТекСтрокаСделкиЗаДень.ТипСделки = Перечисления.ТипыСделок.Продажа Тогда
			Движение = Движения.ОстаткиДенежныхСредств.Добавить();
			Движение.ВидДвижения = ВидДвиженияНакопления.Приход;
			Движение.Период = ТекСтрокаСделкиЗаДень.ДатаВремяСделки;
			Движение.БрокерскийСчет = БрокерскийСчет;
			Движение.Валюта = ТекСтрокаСделкиЗаДень.Валюта;
			Движение.Сумма = ТекСтрокаСделкиЗаДень.Сумма;
			Движение.ПричинаИзменения = Перечисления.ПричиныИзмененияОстатковДенежныхСредств.ПродажаЦеннойБумаги;			
			Если Не ВалютаОбмена.Пустая() Тогда
				Движение.ПричинаИзменения = Перечисления.ПричиныИзмененияОстатковДенежныхСредств.ОбменВалютыПоступление;
				ПричинаИзмененияОбратная = Перечисления.ПричиныИзмененияОстатковДенежныхСредств.ОбменВалютыСписание;
				КоличествоВалюты = ТекСтрокаСделкиЗаДень.Количество;
				ВидДвиженияОбратный = ВидДвиженияНакопления.Расход;
			КонецЕсли;			
		КонецЕсли;
		
		Если Не ВалютаОбмена.Пустая() Тогда
			Движение = Движения.ОстаткиДенежныхСредств.Добавить();
			Движение.ВидДвижения = ВидДвиженияОбратный;
			Движение.Период = ТекСтрокаСделкиЗаДень.ДатаВремяСделки;
			Движение.БрокерскийСчет = БрокерскийСчет;
			Движение.Валюта = ВалютаОбмена;
			Движение.Сумма = КоличествоВалюты;
			Движение.ПричинаИзменения = ПричинаИзмененияОбратная;			
		КонецЕсли;	
		
		Если ТекСтрокаСделкиЗаДень.Комиссия <> 0 Тогда
			Движение = Движения.ОстаткиДенежныхСредств.Добавить();
			Движение.ВидДвижения = ВидДвиженияНакопления.Расход;
			Движение.Период = ТекСтрокаСделкиЗаДень.ДатаВремяСделки;
			Движение.БрокерскийСчет = БрокерскийСчет;
			Движение.Валюта = ТекСтрокаСделкиЗаДень.Валюта;
			Движение.Сумма = ТекСтрокаСделкиЗаДень.Комиссия;
			Движение.ПричинаИзменения = Перечисления.ПричиныИзмененияОстатковДенежныхСредств.Комиссия;
		КонецЕсли;				
				
	КонецЦикла;

КонецПроцедуры

#КонецОбласти

#КонецЕсли
