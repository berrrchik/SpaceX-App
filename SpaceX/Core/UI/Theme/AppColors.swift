import UIKit

struct AppColors {
    // Основные цвета фона
    static let black = UIColor.black
    static let clear = UIColor.clear
    static let darkGray = UIColor.darkGray  // Для imageContainer в RocketView
    static let cardGray = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.00)  // Для cardView, square, grayRectangle
    static let pageControlContainer = UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1.00)  // Для pageControlContainer в RocketViewController
    static let buttonBackgroundGray = UIColor.gray.withAlphaComponent(0.3)  // Для showLaunchesButton в RocketView
    
    // Цвета текста и индикаторов
    static let white = UIColor.white
    static let lightGray = UIColor.lightGray  // Для pageControl.pageIndicatorTintColor
    static let textGray56 = UIColor(red: 0.56, green: 0.56, blue: 0.56, alpha: 1.00)  // Для dateLabel, measureLabel, inactiveColor, error text
    static let labelGray79 = UIColor(red: 0.79, green: 0.79, blue: 0.79, alpha: 1.00)  // Для label в RocketView (firstFlightLabel и т.д.)
    static let activeBlack07 = UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1.00)  // Для activeColor в CustomToggleView
    static let buttonTint96 = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00)  // Для showLaunchesButton.tintColor
}
