# ============================================
#           CISTIERS SERVICE MANAGER
#        Управление службами Windows
#           Автор: RealMikoto
# ============================================

Clear-Host

# Список служб для управления
$global:Services = @(
    "SysMain",
    "PcaSvc",
    "DPS",
    "DusmSvc",
    "EventLog",
    "Appinfo",
    "Bam",
    "Cdpusersvc",
    "DiagTrack"
)

# ============================================
# ФУНКЦИЯ ДЛЯ РОВНОЙ ЛИНИИ
# ============================================
function Line {
    Write-Host (" " * 2 + "=" * 60) -ForegroundColor DarkBlue
}

function DoubleLine {
    Write-Host (" " * 2 + "═" * 60) -ForegroundColor DarkBlue
}

function CenterText {
    param([string]$Text, [string]$Color = "Cyan")
    $width = 60
    $padding = [math]::Max(0, [math]::Floor(($width - $Text.Length) / 2))
    $spaces = " " * $padding
    Write-Host (" " * 2 + $spaces + $Text) -ForegroundColor $Color
}

function LeftText {
    param([string]$Text, [string]$Color = "White")
    Write-Host (" " * 4 + $Text) -ForegroundColor $Color
}

# ============================================
# ФУНКЦИЯ ДЛЯ ОСТАНОВКИ СЛУЖБЫ С ТАЙМАУТОМ
# ============================================
function Stop-ServiceWithTimeout {
    param(
        [string]$ServiceName,
        [int]$TimeoutSeconds = 10
    )
    
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    
    if (-not $service) {
        return @{ Success = $false; Status = "НЕ НАЙДЕНА"; Error = "Служба не найдена" }
    }
    
    if ($service.Status -eq "Stopped") {
        return @{ Success = $true; Status = "УЖЕ ОСТАНОВЛЕНА"; Error = $null }
    }
    
    try {
        # Пытаемся остановить службу
        Write-Host (" " * 6) -NoNewline
        Write-Host "Остановка " -NoNewline -ForegroundColor DarkGray
        Write-Host $ServiceName -NoNewline -ForegroundColor White
        Write-Host " ... " -NoNewline -ForegroundColor DarkGray
        
        Stop-Service -Name $ServiceName -Force -ErrorAction Stop
        
        # Ждём остановки с таймаутом
        $timeout = (Get-Date).AddSeconds($TimeoutSeconds)
        $dots = 0
        
        while ($service.Status -ne "Stopped") {
            Start-Sleep -Milliseconds 500
            $service.Refresh()
            
            # Обновляем индикатор ожидания
            if ($dots -lt 3) {
                Write-Host "." -NoNewline -ForegroundColor DarkGray
                $dots++
            } else {
                Write-Host "." -NoNewline -ForegroundColor DarkGray
                $dots = 0
            }
            
            # Проверяем таймаут
            if ((Get-Date) -gt $timeout) {
                Write-Host ""
                return @{ 
                    Success = $false
                    Status = "ТАЙМАУТ"
                    Error = "Превышено время ожидания ($TimeoutSeconds сек)"
                }
            }
        }
        
        Write-Host " ✓" -ForegroundColor Green
        return @{ Success = $true; Status = "ОСТАНОВЛЕНА"; Error = $null }
        
    } catch {
        return @{ 
            Success = $false
            Status = "ОШИБКА"
            Error = $_.Exception.Message
        }
    }
}

# ============================================
# ФУНКЦИЯ 1: Проверка состояния служб
# ============================================
function Проверить-СостояниеСлужб {
    Clear-Host
    Write-Host ""
    DoubleLine
    CenterText "ПРОВЕРКА СОСТОЯНИЯ СЛУЖБ" "Cyan"
    DoubleLine
    Write-Host ""
    
    $running = 0
    $stopped = 0
    $notFound = 0
    
    foreach ($s in $global:Services) {
        $service = Get-Service -Name $s -ErrorAction SilentlyContinue
        
        if ($service) {
            if ($service.Status -eq "Running") {
                Write-Host (" " * 4) -NoNewline
                Write-Host "● " -NoNewline -ForegroundColor Green
                Write-Host $s.PadRight(18) -NoNewline -ForegroundColor White
                Write-Host "→ " -NoNewline -ForegroundColor DarkBlue
                Write-Host "ЗАПУЩЕНА" -ForegroundColor Green
                $running++
            } else {
                Write-Host (" " * 4) -NoNewline
                Write-Host "○ " -NoNewline -ForegroundColor DarkGray
                Write-Host $s.PadRight(18) -NoNewline -ForegroundColor White
                Write-Host "→ " -NoNewline -ForegroundColor DarkBlue
                Write-Host "ОСТАНОВЛЕНА" -ForegroundColor DarkGray
                $stopped++
            }
        } else {
            Write-Host (" " * 4) -NoNewline
            Write-Host "✗ " -NoNewline -ForegroundColor Yellow
            Write-Host $s.PadRight(18) -NoNewline -ForegroundColor White
            Write-Host "→ " -NoNewline -ForegroundColor DarkBlue
            Write-Host "НЕ НАЙДЕНА" -ForegroundColor Yellow
            $notFound++
        }
    }
    
    Write-Host ""
    Line
    Write-Host (" " * 4) -NoNewline
    Write-Host "ЗАПУЩЕНО: " -NoNewline -ForegroundColor DarkGray
    Write-Host $running.ToString().PadLeft(2) -NoNewline -ForegroundColor Green
    Write-Host "  |  " -NoNewline -ForegroundColor DarkBlue
    Write-Host "ОСТАНОВЛЕНО: " -NoNewline -ForegroundColor DarkGray
    Write-Host $stopped.ToString().PadLeft(2) -NoNewline -ForegroundColor DarkGray
    Write-Host "  |  " -NoNewline -ForegroundColor DarkBlue
    Write-Host "НЕ НАЙДЕНО: " -NoNewline -ForegroundColor DarkGray
    Write-Host $notFound.ToString().PadLeft(2) -ForegroundColor Yellow
    Line
    Write-Host ""
    Write-Host (" " * 4 + "Нажмите любую клавишу для возврата в меню...") -ForegroundColor DarkGray
    Read-Host
}

# ============================================
# ФУНКЦИЯ 2: Включение служб
# ============================================
function Включить-Службы {
    Clear-Host
    Write-Host ""
    DoubleLine
    CenterText "ВКЛЮЧЕНИЕ СЛУЖБ" "Cyan"
    DoubleLine
    Write-Host ""
    
    $success = 0
    $failed = 0
    $alreadyRunning = 0
    
    foreach ($s in $global:Services) {
        $service = Get-Service -Name $s -ErrorAction SilentlyContinue
        
        if ($service) {
            try {
                Set-Service -Name $s -StartupType Automatic -ErrorAction Stop
                
                if ($service.Status -eq "Running") {
                    Write-Host (" " * 4) -NoNewline
                    Write-Host "● " -NoNewline -ForegroundColor Blue
                    Write-Host $s.PadRight(18) -NoNewline -ForegroundColor White
                    Write-Host "→ " -NoNewline -ForegroundColor DarkBlue
                    Write-Host "УЖЕ ЗАПУЩЕНА" -ForegroundColor Blue
                    $alreadyRunning++
                } else {
                    Start-Service -Name $s -ErrorAction Stop
                    Write-Host (" " * 4) -NoNewline
                    Write-Host "● " -NoNewline -ForegroundColor Green
                    Write-Host $s.PadRight(18) -NoNewline -ForegroundColor White
                    Write-Host "→ " -NoNewline -ForegroundColor DarkBlue
                    Write-Host "ЗАПУЩЕНА" -ForegroundColor Green
                    $success++
                }
            } catch {
                Write-Host (" " * 4) -NoNewline
                Write-Host "✗ " -NoNewline -ForegroundColor Red
                Write-Host $s.PadRight(18) -NoNewline -ForegroundColor White
                Write-Host "→ " -NoNewline -ForegroundColor DarkBlue
                Write-Host "ОШИБКА" -ForegroundColor Red
                $failed++
            }
        } else {
            Write-Host (" " * 4) -NoNewline
            Write-Host "✗ " -NoNewline -ForegroundColor Yellow
            Write-Host $s.PadRight(18) -NoNewline -ForegroundColor White
            Write-Host "→ " -NoNewline -ForegroundColor DarkBlue
            Write-Host "НЕ НАЙДЕНА" -ForegroundColor Yellow
            $failed++
        }
    }
    
    Write-Host ""
    Line
    Write-Host (" " * 4) -NoNewline
    Write-Host "УСПЕШНО: " -NoNewline -ForegroundColor DarkGray
    Write-Host $success.ToString().PadLeft(2) -NoNewline -ForegroundColor Green
    Write-Host "  |  " -NoNewline -ForegroundColor DarkBlue
    Write-Host "УЖЕ ЗАПУЩЕНО: " -NoNewline -ForegroundColor DarkGray
    Write-Host $alreadyRunning.ToString().PadLeft(2) -NoNewline -ForegroundColor Blue
    Write-Host "  |  " -NoNewline -ForegroundColor DarkBlue
    Write-Host "ОШИБОК: " -NoNewline -ForegroundColor DarkGray
    Write-Host $failed.ToString().PadLeft(2) -ForegroundColor Red
    Line
    Write-Host ""
    Write-Host (" " * 4 + "Нажмите любую клавишу для возврата в меню...") -ForegroundColor DarkGray
    Read-Host
}

# ============================================
# ФУНКЦИЯ 3: Отключение служб (С ТАЙМАУТОМ 10 СЕКУНД)
# ============================================
function Отключить-Службы {
    Clear-Host
    Write-Host ""
    DoubleLine
    CenterText "ОТКЛЮЧЕНИЕ СЛУЖБ" "Cyan"
    CenterText "(Таймаут остановки: 10 секунд)" "DarkGray"
    DoubleLine
    Write-Host ""
    
    $success = 0
    $failed = 0
    $alreadyStopped = 0
    $timeoutCount = 0
    
    foreach ($s in $global:Services) {
        $service = Get-Service -Name $s -ErrorAction SilentlyContinue
        
        if (-not $service) {
            Write-Host (" " * 4) -NoNewline
            Write-Host "✗ " -NoNewline -ForegroundColor Yellow
            Write-Host $s.PadRight(18) -NoNewline -ForegroundColor White
            Write-Host "→ " -NoNewline -ForegroundColor DarkBlue
            Write-Host "НЕ НАЙДЕНА" -ForegroundColor Yellow
            $failed++
            continue
        }
        
        if ($service.Status -eq "Stopped") {
            Write-Host (" " * 4) -NoNewline
            Write-Host "○ " -NoNewline -ForegroundColor Yellow
            Write-Host $s.PadRight(18) -NoNewline -ForegroundColor White
            Write-Host "→ " -NoNewline -ForegroundColor DarkBlue
            Write-Host "УЖЕ ОСТАНОВЛЕНА" -ForegroundColor Yellow
            $alreadyStopped++
            # Всё равно устанавливаем тип запуска "Отключена"
            try {
                Set-Service -Name $s -StartupType Disabled -ErrorAction Stop
            } catch {
                # Игнорируем ошибку, если не удалось изменить тип запуска
            }
            continue
        }
        
        # Пытаемся остановить службу с таймаутом
        try {
            Write-Host (" " * 4) -NoNewline
            Write-Host "⏳ " -NoNewline -ForegroundColor Cyan
            Write-Host $s.PadRight(18) -NoNewline -ForegroundColor White
            Write-Host "→ " -NoNewline -ForegroundColor DarkBlue
            Write-Host "Остановка... " -NoNewline -ForegroundColor DarkGray
            
            # Отправляем команду остановки
            Stop-Service -Name $s -Force -ErrorAction Stop
            
            # Ждём остановки с таймаутом 10 секунд
            $timeout = (Get-Date).AddSeconds(10)
            $waiting = $true
            $dotCount = 0
            
            while ($waiting) {
                Start-Sleep -Milliseconds 200
                $service.Refresh()
                
                if ($service.Status -eq "Stopped") {
                    Write-Host "✓" -ForegroundColor Green
                    $waiting = $false
                    $success++
                    break
                }
                
                # Показываем анимацию точек
                $dotCount++
                if ($dotCount -eq 5) {
                    Write-Host "." -NoNewline -ForegroundColor DarkGray
                    $dotCount = 0
                }
                
                # Проверяем таймаут
                if ((Get-Date) -gt $timeout) {
                    Write-Host ""
                    Write-Host (" " * 4) -NoNewline
                    Write-Host "⏰ " -NoNewline -ForegroundColor Red
                    Write-Host $s.PadRight(18) -NoNewline -ForegroundColor White
                    Write-Host "→ " -NoNewline -ForegroundColor DarkBlue
                    Write-Host "ТАЙМАУТ (10 сек)" -ForegroundColor Red
                    Write-Host (" " * 6) -NoNewline
                    Write-Host "⚠ " -NoNewline -ForegroundColor Yellow
                    Write-Host "Служба не остановилась, переходим к следующей..." -ForegroundColor Yellow
                    $timeoutCount++
                    $failed++
                    $waiting = $false
                }
            }
            
            # Если служба остановилась успешно, меняем тип запуска
            if ($service.Status -eq "Stopped") {
                try {
                    Set-Service -Name $s -StartupType Disabled -ErrorAction Stop
                } catch {
                    Write-Host (" " * 6) -NoNewline
                    Write-Host "⚠ " -NoNewline -ForegroundColor Yellow
                    Write-Host "Не удалось изменить тип запуска: " -NoNewline -ForegroundColor Yellow
                    Write-Host $_.Exception.Message -ForegroundColor DarkGray
                }
            }
            
        } catch {
            Write-Host ""
            Write-Host (" " * 4) -NoNewline
            Write-Host "✗ " -NoNewline -ForegroundColor Red
            Write-Host $s.PadRight(18) -NoNewline -ForegroundColor White
            Write-Host "→ " -NoNewline -ForegroundColor DarkBlue
            Write-Host "ОШИБКА" -ForegroundColor Red
            Write-Host (" " * 6) -NoNewline
            Write-Host "⚠ " -NoNewline -ForegroundColor Yellow
            Write-Host "Переходим к следующей службе..." -ForegroundColor Yellow
            $failed++
        }
    }
    
    Write-Host ""
    Line
    Write-Host (" " * 4) -NoNewline
    Write-Host "ОСТАНОВЛЕНО: " -NoNewline -ForegroundColor DarkGray
    Write-Host $success.ToString().PadLeft(2) -NoNewline -ForegroundColor DarkGray
    Write-Host "  |  " -NoNewline -ForegroundColor DarkBlue
    Write-Host "УЖЕ ОСТАНОВЛЕНО: " -NoNewline -ForegroundColor DarkGray
    Write-Host $alreadyStopped.ToString().PadLeft(2) -NoNewline -ForegroundColor Yellow
    Write-Host "  |  " -NoNewline -ForegroundColor DarkBlue
    Write-Host "ТАЙМАУТОВ: " -NoNewline -ForegroundColor DarkGray
    Write-Host $timeoutCount.ToString().PadLeft(2) -NoNewline -ForegroundColor Red
    Write-Host "  |  " -NoNewline -ForegroundColor DarkBlue
    Write-Host "ОШИБОК: " -NoNewline -ForegroundColor DarkGray
    Write-Host $failed.ToString().PadLeft(2) -ForegroundColor Red
    Line
    
    if ($timeoutCount -gt 0) {
        Write-Host ""
        Write-Host (" " * 4) -NoNewline
        Write-Host "⚠ " -NoNewline -ForegroundColor Yellow
        Write-Host "Некоторые службы не остановились за 10 секунд." -ForegroundColor Yellow
        Write-Host (" " * 6) -NoNewline
        Write-Host "Возможно, они были остановлены вручную или заблокированы системой." -ForegroundColor DarkGray
    }
    
    Write-Host ""
    Write-Host (" " * 4 + "Нажмите любую клавишу для возврата в меню...") -ForegroundColor DarkGray
    Read-Host
}

# ============================================
# ГЛАВНОЕ МЕНЮ
# ============================================
function Показать-Меню {
    Clear-Host
    
    Write-Host ""
    DoubleLine
    CenterText "  ██████╗██╗███████╗████████╗██╗███████╗██████╗ ███████╗" "Cyan"
    CenterText " ██╔════╝██║██╔════╝╚══██╔══╝██║██╔════╝██╔══██╗██╔════╝" "Cyan"
    CenterText " ██║     ██║███████╗   ██║   ██║█████╗  ██████╔╝███████╗" "Cyan"
    CenterText " ██║     ██║╚════██║   ██║   ██║██╔══╝  ██╔══██╗╚════██║" "Cyan"
    CenterText " ╚██████╗██║███████║   ██║   ██║███████╗██║  ██║███████║" "Cyan"
    CenterText "  ╚═════╝╚═╝╚══════╝   ╚═╝   ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝" "Cyan"
    Write-Host ""
    CenterText "Управление службами Windows" "White"
    CenterText "v1.0 CISTIERS" "Gray"
    CenterText "Автор: RealMikoto" "Gray"
    DoubleLine
    CenterText "ГЛАВНОЕ МЕНЮ" "Cyan"
    DoubleLine
    Write-Host ""
    LeftText "[1]  Проверить состояние служб" "White"
    LeftText "[2]  Включить службы (Запустить и установить 'Авто')" "White"
    LeftText "[3]  Отключить службы (Остановить и установить 'Откл')" "White"
    LeftText "[Q]  Выход" "White"
    Write-Host ""
    DoubleLine
    CenterText "CISTIERS – ВЫБЕРИТЕ ДЕЙСТВИЕ" "White"
    DoubleLine
    Write-Host ""
}

# ============================================
# ОСНОВНАЯ ПРОГРАММА
# ============================================

do {
    Показать-Меню
    Write-Host (" " * 4 + "Введите ваш выбор: ") -NoNewline -ForegroundColor Cyan
    $choice = Read-Host
    
    switch ($choice.ToUpper()) {
        "1" {
            Проверить-СостояниеСлужб
        }
        "2" {
            Включить-Службы
        }
        "3" {
            Clear-Host
            Write-Host ""
            Line
            Write-Host (" " * 4) -NoNewline
            Write-Host "ВНИМАНИЕ! Отключение служб может повлиять на систему" -ForegroundColor Yellow
            Write-Host (" " * 4) -NoNewline
            Write-Host "Таймаут остановки каждой службы: 10 секунд" -ForegroundColor DarkGray
            Line
            Write-Host ""
            Write-Host (" " * 4 + "Продолжить? (Y/N): ") -NoNewline -ForegroundColor Cyan
            $confirm = Read-Host
            if ($confirm.ToUpper() -eq "Y") {
                Отключить-Службы
            } else {
                Write-Host (" " * 4 + "Операция отменена.") -ForegroundColor Yellow
                Write-Host ""
                Write-Host (" " * 4 + "Нажмите любую клавишу для продолжения...") -ForegroundColor DarkGray
                Read-Host
            }
        }
        "Q" {
            Clear-Host
            Write-Host ""
            DoubleLine
            CenterText "CISTIERS – ДО СВИДАНИЯ!" "Cyan"
            CenterText "Спасибо за использование!" "White"
            CenterText "RealMikoto" "Gray"
            DoubleLine
            Write-Host ""
            break
        }
        default {
            Write-Host ""
            Write-Host (" " * 4 + "Неверный выбор! Выберите 1, 2, 3 или Q.") -ForegroundColor Red
            Write-Host ""
            Write-Host (" " * 4 + "Нажмите любую клавишу для продолжения...") -ForegroundColor DarkGray
            Read-Host
        }
    }
} while ($true)