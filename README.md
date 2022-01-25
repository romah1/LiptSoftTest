# LiptSoftTest

> Используя API с кошечками (https://docs.thecatapi.com/pagination)
> реализовать подгрузку картинок, их кэширование и отображение в виде таблицы
> (слева в ячейке располагается картинка фиксированной высоты 50 и
> динамической длины, в зависимости от ратио картинки. Плейсхолдер можно взять
> любой, хоть просто красить фон imageView). Справа от картинки на расстоянии
> 16pt располагается один лейбл по центру с информацией о размере. Т.о. ратио
> картинок будет не одинаковым.
> По нажатию на ячейку идет переход к деталям - сверху картинка, а снизу
> JSON представление объекта в формате prettyPrint.
Важно:
- сделать это на SwiftUI + Combine
- избегать сторонних решений, максимум натива
