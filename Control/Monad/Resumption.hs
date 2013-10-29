module Control.Monad.Resumption where

import Control.Monad
import Control.Monad.Trans
import Control.Applicative
import Control.Monad.IO.Class


newtype ResT m a = ResT { deResT :: m (Either a (ResT m a)) }

runResT :: (Monad m) => ResT m a -> m a
runResT (ResT m)  = do
                      x <- m
                      case x of 
                        Left val -> return val
                        Right m -> runResT m

instance Monad m => Monad (ResT m) where
  return x = ResT $ return $ Left x
  ResT m >>= f =  ResT $ do 
                          x <- m 
                          case x of
                             Left  val -> return $ Right $ f val 
                             Right res -> return $ Right $ res >>= f 

instance MonadTrans ResT where
  lift m = ResT (m >>= return . Left)


instance Monad m => Functor (ResT m) where
  fmap f (ResT m) = ResT $ do
                             x <- m
                             case x of
                                Left val  -> return $ Left $ f val
                                Right res -> return $ Right $ res >>= return . f

instance Monad m => Applicative (ResT m) where
  pure = return
  (<*>) = ap
                              
instance MonadIO m => MonadIO (ResT m) where
  liftIO = lift . liftIO
